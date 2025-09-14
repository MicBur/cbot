#include "marketmodel_improved.h"
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonValue>
#include <QDateTime>
#include <QDebug>
#include <algorithm>
#include <execution>

// MarketRow memory pool implementation
static MarketRowPool* g_rowPool = nullptr;

void* MarketRow::operator new(size_t size) {
    if (!g_rowPool) {
        g_rowPool = &MarketRowPool::getInstance();
    }
    return g_rowPool->allocate();
}

void MarketRow::operator delete(void* ptr) {
    if (g_rowPool) {
        g_rowPool->deallocate(ptr);
    }
}

// MarketRowPool implementation
MarketRowPool& MarketRowPool::getInstance() {
    static MarketRowPool instance;
    return instance;
}

MarketRowPool::MarketRowPool() {
    expandPool();
}

MarketRowPool::~MarketRowPool() {
    // Memory automatically freed by unique_ptr
}

void* MarketRowPool::allocate() {
    std::lock_guard<std::mutex> lock(m_mutex);
    
    // Find a block with free slots
    for (auto& block : m_blocks) {
        if (!block.freeList.empty()) {
            void* ptr = block.freeList.back();
            block.freeList.pop_back();
            m_allocated++;
            return ptr;
        }
    }
    
    // All blocks full, expand pool
    expandPool();
    return allocate();
}

void MarketRowPool::deallocate(void* ptr) {
    std::lock_guard<std::mutex> lock(m_mutex);
    
    // Find which block owns this pointer
    for (auto& block : m_blocks) {
        char* blockStart = block.memory.get();
        char* blockEnd = blockStart + (m_blockSize * sizeof(MarketRow));
        
        if (ptr >= blockStart && ptr < blockEnd) {
            block.freeList.push_back(ptr);
            m_allocated--;
            return;
        }
    }
    
    qWarning() << "MarketRowPool: Attempted to deallocate unknown pointer";
}

void MarketRowPool::expandPool() {
    Block newBlock;
    newBlock.memory = std::make_unique<char[]>(m_blockSize * sizeof(MarketRow));
    
    // Initialize free list
    char* ptr = newBlock.memory.get();
    for (size_t i = 0; i < m_blockSize; ++i) {
        newBlock.freeList.push_back(ptr + i * sizeof(MarketRow));
    }
    
    m_blocks.push_back(std::move(newBlock));
    m_poolSize += m_blockSize;
    
    // Double block size for next expansion (up to a limit)
    if (m_blockSize < 16384) {
        m_blockSize *= 2;
    }
}

// MarketModel implementation
MarketModel::MarketModel(QObject* parent) : QAbstractListModel(parent) {
    // Pre-allocate some capacity
    m_rows.reserve(100);
    m_viewIndices.reserve(100);
}

MarketModel::~MarketModel() {
    // Unique_ptr handles cleanup
}

int MarketModel::rowCount(const QModelIndex& parent) const {
    if (parent.isValid()) return 0;
    
    std::shared_lock<std::shared_mutex> lock(m_mutex);
    return static_cast<int>(m_viewDirty ? m_rows.size() : m_viewIndices.size());
}

QVariant MarketModel::data(const QModelIndex& index, int role) const {
    if (!index.isValid() || index.row() < 0 || index.row() >= rowCount()) {
        return QVariant();
    }
    
    std::shared_lock<std::shared_mutex> lock(m_mutex);
    
    // Get actual row index (considering filtering/sorting)
    size_t rowIdx = m_viewDirty ? static_cast<size_t>(index.row()) : m_viewIndices[static_cast<size_t>(index.row())];
    
    if (rowIdx >= m_rows.size()) {
        return QVariant();
    }
    
    const auto& row = *m_rows[rowIdx];
    
    switch (role) {
        case SymbolRole: return row.symbol;
        case PriceRole: return row.price;
        case ChangeRole: return row.change;
        case ChangePercentRole: return row.changePercent;
        case DirectionRole: return row.direction;
        case VolumeRole: return row.volume;
        case DayHighRole: return row.dayHigh;
        case DayLowRole: return row.dayLow;
        case PreviousCloseRole: return row.previousClose;
        case LastUpdateRole: return row.lastUpdateTime;
        default: return QVariant();
    }
}

QHash<int, QByteArray> MarketModel::roleNames() const {
    return {
        {SymbolRole, "symbol"},
        {PriceRole, "price"},
        {ChangeRole, "change"},
        {ChangePercentRole, "changePercent"},
        {DirectionRole, "direction"},
        {VolumeRole, "volume"},
        {DayHighRole, "dayHigh"},
        {DayLowRole, "dayLow"},
        {PreviousCloseRole, "previousClose"},
        {LastUpdateRole, "lastUpdate"}
    };
}

void MarketModel::updateFromJson(const QByteArray& jsonBytes) {
    auto start = std::chrono::steady_clock::now();
    
    QJsonParseError error;
    QJsonDocument doc = QJsonDocument::fromJson(jsonBytes, &error);
    
    if (error.error != QJsonParseError::NoError) {
        // Try Python dict format conversion
        QString dataStr = QString::fromUtf8(jsonBytes);
        if (dataStr.startsWith("{'") || dataStr.startsWith("{\"")) {
            QString jsonStr = dataStr;
            jsonStr.replace("'", "\"");
            doc = QJsonDocument::fromJson(jsonStr.toUtf8(), &error);
        }
        
        if (error.error != QJsonParseError::NoError) {
            qWarning() << "MarketModel: JSON parse error:" << error.errorString();
            return;
        }
    }
    
    if (doc.isObject()) {
        updateFromMap(doc.object());
    } else if (doc.isArray()) {
        // Handle array format
        QJsonArray array = doc.array();
        std::vector<MarketRow> rows;
        rows.reserve(static_cast<size_t>(array.size()));
        
        for (const auto& value : array) {
            if (value.isObject()) {
                QJsonObject obj = value.toObject();
                auto row = std::make_unique<MarketRow>();
                row->symbol = obj.value("symbol").toString();
                row->price = obj.value("price").toDouble();
                row->change = obj.value("change").toDouble();
                row->changePercent = obj.value("change_percent").toDouble();
                row->volume = obj.value("volume").toDouble();
                row->dayHigh = obj.value("day_high").toDouble();
                row->dayLow = obj.value("day_low").toDouble();
                row->previousClose = obj.value("previous_close").toDouble();
                row->direction = row->change > 0 ? 1 : (row->change < 0 ? -1 : 0);
                row->lastUpdateTime = QDateTime::currentMSecsSinceEpoch();
                rows.push_back(*row);
            }
        }
        
        updateBatch(rows);
    }
    
    auto end = std::chrono::steady_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end - start);
    
    m_stats.totalUpdates++;
    m_stats.avgUpdateTimeMs = (m_stats.avgUpdateTimeMs * (m_stats.totalUpdates - 1) + duration.count()) / m_stats.totalUpdates;
}

void MarketModel::updateFromMap(const QJsonObject& marketData) {
    emit dataUpdateStarted();
    
    beginBatchUpdate();
    
    // Track symbols for removal detection
    QSet<QString> seenSymbols;
    int updatedCount = 0;
    
    // Update or insert rows
    for (auto it = marketData.begin(); it != marketData.end(); ++it) {
        const QString& symbol = it.key();
        if (!it.value().isObject()) continue;
        
        seenSymbols.insert(symbol);
        QJsonObject obj = it.value().toObject();
        
        auto row = std::make_unique<MarketRow>();
        row->symbol = symbol;
        row->price = obj.value("price").toDouble();
        row->change = obj.value("change").toDouble();
        row->changePercent = obj.value("change_percent").toDouble();
        row->volume = obj.value("volume").toDouble(row->volume);
        row->dayHigh = obj.value("day_high").toDouble(row->dayHigh);
        row->dayLow = obj.value("day_low").toDouble(row->dayLow);
        row->previousClose = obj.value("previous_close").toDouble(row->previousClose);
        row->direction = row->change > 0 ? 1 : (row->change < 0 ? -1 : 0);
        row->lastUpdateTime = QDateTime::currentMSecsSinceEpoch();
        
        updateSymbol(symbol, *row);
        updatedCount++;
    }
    
    // Remove symbols not in update
    std::vector<QString> toRemove;
    {
        std::shared_lock<std::shared_mutex> lock(m_mutex);
        for (const auto& row : m_rows) {
            if (!seenSymbols.contains(row->symbol)) {
                toRemove.push_back(row->symbol);
            }
        }
    }
    
    for (const auto& symbol : toRemove) {
        removeSymbol(symbol);
    }
    
    endBatchUpdate();
    
    emit dataUpdateCompleted(updatedCount);
    m_stats.batchUpdates++;
}

void MarketModel::updateBatch(const std::vector<MarketRow>& rows) {
    emit dataUpdateStarted();
    
    beginBatchUpdate();
    
    for (const auto& row : rows) {
        updateSymbol(row.symbol, row);
    }
    
    endBatchUpdate();
    
    emit dataUpdateCompleted(static_cast<int>(rows.size()));
    m_stats.batchUpdates++;
}

void MarketModel::updateSymbol(const QString& symbol, const MarketRow& data) {
    std::unique_lock<std::shared_mutex> lock(m_mutex);
    
    auto it = m_indexMap.find(symbol);
    if (it != m_indexMap.end()) {
        // Update existing row
        size_t idx = it->second;
        if (updateExistingRow(idx, data)) {
            // Find view index and emit change
            if (!m_viewDirty) {
                auto viewIt = std::find(m_viewIndices.begin(), m_viewIndices.end(), idx);
                if (viewIt != m_viewIndices.end()) {
                    int viewIdx = static_cast<int>(std::distance(m_viewIndices.begin(), viewIt));
                    lock.unlock();
                    
                    QModelIndex modelIdx = index(viewIdx);
                    emit dataChanged(modelIdx, modelIdx);
                    triggerRowAnimation(viewIdx);
                }
            }
        }
    } else {
        // Insert new row
        auto newRow = std::make_unique<MarketRow>(data);
        size_t newIdx = insertNewRow(std::move(newRow));
        
        if (!m_viewDirty && matchesFilter(*m_rows[newIdx])) {
            // Add to view and resort if needed
            m_viewIndices.push_back(newIdx);
            if (m_sortOrder != SortOrder::None) {
                sortView();
            }
            
            // Find position in view
            auto viewIt = std::find(m_viewIndices.begin(), m_viewIndices.end(), newIdx);
            int viewIdx = static_cast<int>(std::distance(m_viewIndices.begin(), viewIt));
            
            lock.unlock();
            
            beginInsertRows(QModelIndex(), viewIdx, viewIdx);
            endInsertRows();
            triggerRowAnimation(viewIdx);
        }
    }
    
    m_stats.individualUpdates++;
}

void MarketModel::removeSymbol(const QString& symbol) {
    std::unique_lock<std::shared_mutex> lock(m_mutex);
    
    auto it = m_indexMap.find(symbol);
    if (it != m_indexMap.end()) {
        size_t idx = it->second;
        
        // Find view index before removal
        int viewIdx = -1;
        if (!m_viewDirty) {
            auto viewIt = std::find(m_viewIndices.begin(), m_viewIndices.end(), idx);
            if (viewIt != m_viewIndices.end()) {
                viewIdx = static_cast<int>(std::distance(m_viewIndices.begin(), viewIt));
            }
        }
        
        removeRowAt(idx);
        
        if (viewIdx >= 0) {
            lock.unlock();
            
            beginRemoveRows(QModelIndex(), viewIdx, viewIdx);
            endRemoveRows();
        }
    }
}

void MarketModel::clear() {
    beginResetModel();
    
    std::unique_lock<std::shared_mutex> lock(m_mutex);
    m_rows.clear();
    m_indexMap.clear();
    m_viewIndices.clear();
    m_viewDirty = true;
    
    endResetModel();
    emit countChanged();
}

void MarketModel::setFilter(const QString& filter) {
    if (m_filter != filter) {
        m_filter = filter;
        rebuildView();
        emit filterChanged();
    }
}

void MarketModel::setSortOrder(SortOrder order) {
    if (m_sortOrder != order) {
        m_sortOrder = order;
        rebuildView();
        emit sortOrderChanged();
    }
}

void MarketModel::setLoading(bool loading) {
    if (m_loading != loading) {
        m_loading = loading;
        emit loadingChanged();
    }
}

void MarketModel::reserveCapacity(int size) {
    std::unique_lock<std::shared_mutex> lock(m_mutex);
    m_rows.reserve(static_cast<size_t>(size));
    m_viewIndices.reserve(static_cast<size_t>(size));
}

void MarketModel::shrinkToFit() {
    std::unique_lock<std::shared_mutex> lock(m_mutex);
    m_rows.shrink_to_fit();
    m_viewIndices.shrink_to_fit();
}

const MarketRow* MarketModel::getRow(int index) const {
    std::shared_lock<std::shared_mutex> lock(m_mutex);
    
    if (index < 0 || index >= static_cast<int>(m_rows.size())) {
        return nullptr;
    }
    
    size_t idx = m_viewDirty ? static_cast<size_t>(index) : m_viewIndices[static_cast<size_t>(index)];
    return m_rows[idx].get();
}

const MarketRow* MarketModel::findSymbol(const QString& symbol) const {
    std::shared_lock<std::shared_mutex> lock(m_mutex);
    
    auto it = m_indexMap.find(symbol);
    if (it != m_indexMap.end() && it->second < m_rows.size()) {
        return m_rows[it->second].get();
    }
    
    return nullptr;
}

MarketModel::ModelStats MarketModel::getStatistics() const {
    std::shared_lock<std::shared_mutex> lock(m_mutex);
    
    m_stats.memoryUsage = m_rows.size() * sizeof(MarketRow) + 
                         m_rows.capacity() * sizeof(std::unique_ptr<MarketRow>) +
                         m_viewIndices.capacity() * sizeof(size_t);
    
    return m_stats;
}

void MarketModel::rebuildView() {
    beginResetModel();
    
    std::unique_lock<std::shared_mutex> lock(m_mutex);
    
    m_viewIndices.clear();
    m_viewIndices.reserve(m_rows.size());
    
    // Apply filter
    for (size_t i = 0; i < m_rows.size(); ++i) {
        if (matchesFilter(*m_rows[i])) {
            m_viewIndices.push_back(i);
        }
    }
    
    // Apply sort
    if (m_sortOrder != SortOrder::None) {
        sortView();
    }
    
    m_viewDirty = false;
    
    lock.unlock();
    
    endResetModel();
    emit countChanged();
}

bool MarketModel::matchesFilter(const MarketRow& row) const {
    if (m_filter.isEmpty()) {
        return true;
    }
    
    return row.symbol.contains(m_filter, Qt::CaseInsensitive);
}

void MarketModel::sortView() {
    auto compareFunc = [this](size_t a, size_t b) -> bool {
        const auto& rowA = *m_rows[a];
        const auto& rowB = *m_rows[b];
        
        switch (m_sortOrder) {
            case SortOrder::SymbolAsc:
                return rowA.symbol < rowB.symbol;
            case SortOrder::SymbolDesc:
                return rowA.symbol > rowB.symbol;
            case SortOrder::PriceAsc:
                return rowA.price < rowB.price;
            case SortOrder::PriceDesc:
                return rowA.price > rowB.price;
            case SortOrder::ChangeAsc:
                return rowA.changePercent < rowB.changePercent;
            case SortOrder::ChangeDesc:
                return rowA.changePercent > rowB.changePercent;
            case SortOrder::VolumeAsc:
                return rowA.volume < rowB.volume;
            case SortOrder::VolumeDesc:
                return rowA.volume > rowB.volume;
            default:
                return false;
        }
    };
    
    std::sort(m_viewIndices.begin(), m_viewIndices.end(), compareFunc);
}

void MarketModel::updateIndices() {
    m_indexMap.clear();
    for (size_t i = 0; i < m_rows.size(); ++i) {
        m_indexMap[m_rows[i]->symbol] = i;
    }
}

void MarketModel::beginBatchUpdate() {
    // Could implement deferred signaling here
}

void MarketModel::endBatchUpdate() {
    if (m_viewDirty) {
        rebuildView();
    }
}

bool MarketModel::updateExistingRow(size_t index, const MarketRow& newData) {
    if (index >= m_rows.size()) {
        return false;
    }
    
    auto& row = *m_rows[index];
    
    // Check if data actually changed
    bool changed = (row.price != newData.price ||
                   row.change != newData.change ||
                   row.changePercent != newData.changePercent ||
                   row.volume != newData.volume ||
                   row.direction != newData.direction);
    
    if (changed) {
        row.price = newData.price;
        row.change = newData.change;
        row.changePercent = newData.changePercent;
        row.volume = newData.volume;
        row.dayHigh = newData.dayHigh;
        row.dayLow = newData.dayLow;
        row.previousClose = newData.previousClose;
        row.direction = newData.direction;
        row.lastUpdateTime = newData.lastUpdateTime;
    }
    
    return changed;
}

size_t MarketModel::insertNewRow(std::unique_ptr<MarketRow> row) {
    size_t newIdx = m_rows.size();
    m_indexMap[row->symbol] = newIdx;
    m_rows.push_back(std::move(row));
    return newIdx;
}

void MarketModel::removeRowAt(size_t index) {
    if (index >= m_rows.size()) {
        return;
    }
    
    // Remove from index map
    m_indexMap.erase(m_rows[index]->symbol);
    
    // Remove from rows
    m_rows.erase(m_rows.begin() + static_cast<ptrdiff_t>(index));
    
    // Update indices for all rows after the removed one
    for (auto& [symbol, idx] : m_indexMap) {
        if (idx > index) {
            idx--;
        }
    }
    
    // Update view indices
    m_viewIndices.erase(
        std::remove_if(m_viewIndices.begin(), m_viewIndices.end(),
                      [index](size_t idx) { return idx == index; }),
        m_viewIndices.end()
    );
    
    for (auto& idx : m_viewIndices) {
        if (idx > index) {
            idx--;
        }
    }
}

void MarketModel::triggerRowAnimation(int viewIndex) {
    emit rowAnimated(viewIndex);
}

// MarketProxyModel implementation
MarketProxyModel::MarketProxyModel(MarketModel* sourceModel, QObject* parent)
    : QAbstractListModel(parent), m_sourceModel(sourceModel) {
    
    connect(sourceModel, &MarketModel::dataChanged, this, &MarketProxyModel::sourceDataChanged);
    connect(sourceModel, &MarketModel::modelReset, this, &MarketProxyModel::sourceDataChanged);
    connect(sourceModel, &MarketModel::rowsInserted, this, &MarketProxyModel::sourceDataChanged);
    connect(sourceModel, &MarketModel::rowsRemoved, this, &MarketProxyModel::sourceDataChanged);
    
    rebuildProxy();
}

void MarketProxyModel::setMinVolume(double volume) {
    if (m_minVolume != volume) {
        m_minVolume = volume;
        rebuildProxy();
    }
}

void MarketProxyModel::setMaxChangePercent(double percent) {
    if (m_maxChangePercent != percent) {
        m_maxChangePercent = percent;
        rebuildProxy();
    }
}

void MarketProxyModel::setWatchlistOnly(bool watchlist) {
    if (m_watchlistOnly != watchlist) {
        m_watchlistOnly = watchlist;
        rebuildProxy();
    }
}

void MarketProxyModel::setWatchlistSymbols(const QStringList& symbols) {
    m_watchlistSymbols = symbols;
    if (m_watchlistOnly) {
        rebuildProxy();
    }
}

int MarketProxyModel::rowCount(const QModelIndex& parent) const {
    if (parent.isValid()) return 0;
    return static_cast<int>(m_proxyIndices.size());
}

QVariant MarketProxyModel::data(const QModelIndex& index, int role) const {
    if (!index.isValid() || index.row() < 0 || index.row() >= static_cast<int>(m_proxyIndices.size())) {
        return QVariant();
    }
    
    int sourceRow = m_proxyIndices[static_cast<size_t>(index.row())];
    return m_sourceModel->data(m_sourceModel->index(sourceRow), role);
}

QHash<int, QByteArray> MarketProxyModel::roleNames() const {
    return m_sourceModel->roleNames();
}

void MarketProxyModel::sourceDataChanged() {
    rebuildProxy();
}

void MarketProxyModel::rebuildProxy() {
    beginResetModel();
    
    m_proxyIndices.clear();
    int sourceCount = m_sourceModel->rowCount();
    
    for (int i = 0; i < sourceCount; ++i) {
        if (acceptsRow(i)) {
            m_proxyIndices.push_back(i);
        }
    }
    
    endResetModel();
}

bool MarketProxyModel::acceptsRow(int sourceRow) const {
    const MarketRow* row = m_sourceModel->getRow(sourceRow);
    if (!row) return false;
    
    // Volume filter
    if (row->volume < m_minVolume) {
        return false;
    }
    
    // Change percent filter
    if (std::abs(row->changePercent) > m_maxChangePercent) {
        return false;
    }
    
    // Watchlist filter
    if (m_watchlistOnly && !m_watchlistSymbols.contains(row->symbol)) {
        return false;
    }
    
    return true;
}