#pragma once
#include <QAbstractListModel>
#include <QJsonObject>
#include <QString>
#include <vector>
#include <memory>
#include <unordered_map>
#include <shared_mutex>
#include <optional>
#include <QPropertyAnimation>
#include <QEasingCurve>

// Market data row with efficient memory layout
struct MarketRow {
    QString symbol;
    double price = 0.0;
    double change = 0.0;
    double changePercent = 0.0;
    double volume = 0.0;
    double dayHigh = 0.0;
    double dayLow = 0.0;
    double previousClose = 0.0;
    qint64 lastUpdateTime = 0;
    int direction = 0; // -1: down, 0: unchanged, 1: up
    
    // Memory pool support
    static void* operator new(size_t size);
    static void operator delete(void* ptr);
};

// Memory pool for MarketRow objects
class MarketRowPool {
public:
    static MarketRowPool& getInstance();
    
    void* allocate();
    void deallocate(void* ptr);
    
    size_t getPoolSize() const { return m_poolSize; }
    size_t getAllocatedCount() const { return m_allocated; }
    
private:
    MarketRowPool();
    ~MarketRowPool();
    
    struct Block {
        std::unique_ptr<char[]> memory;
        std::vector<void*> freeList;
    };
    
    std::vector<Block> m_blocks;
    size_t m_blockSize = 1024;
    size_t m_poolSize = 0;
    size_t m_allocated = 0;
    mutable std::mutex m_mutex;
    
    void expandPool();
};

// Enhanced Market Model with better memory management and performance
class MarketModel : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)
    Q_PROPERTY(bool loading READ isLoading NOTIFY loadingChanged)
    Q_PROPERTY(QString filter READ filter WRITE setFilter NOTIFY filterChanged)
    Q_PROPERTY(SortOrder sortOrder READ sortOrder WRITE setSortOrder NOTIFY sortOrderChanged)

public:
    enum Roles {
        SymbolRole = Qt::UserRole + 1,
        PriceRole,
        ChangeRole,
        ChangePercentRole,
        DirectionRole,
        VolumeRole,
        DayHighRole,
        DayLowRole,
        PreviousCloseRole,
        LastUpdateRole
    };
    Q_ENUM(Roles)
    
    enum class SortOrder {
        None,
        SymbolAsc,
        SymbolDesc,
        PriceAsc,
        PriceDesc,
        ChangeAsc,
        ChangeDesc,
        VolumeAsc,
        VolumeDesc
    };
    Q_ENUM(SortOrder)
    
    explicit MarketModel(QObject* parent = nullptr);
    ~MarketModel() override;
    
    // QAbstractListModel interface
    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;
    
    // Batch update methods for efficiency
    void updateFromJson(const QByteArray& jsonBytes);
    void updateFromMap(const QJsonObject& marketData);
    void updateBatch(const std::vector<MarketRow>& rows);
    
    // Individual update methods
    void updateSymbol(const QString& symbol, const MarketRow& data);
    void removeSymbol(const QString& symbol);
    void clear();
    
    // Filtering and sorting
    QString filter() const { return m_filter; }
    void setFilter(const QString& filter);
    SortOrder sortOrder() const { return m_sortOrder; }
    void setSortOrder(SortOrder order);
    
    // State
    bool isLoading() const { return m_loading; }
    void setLoading(bool loading);
    
    // Performance helpers
    void reserveCapacity(int size);
    void shrinkToFit();
    
    // Direct access for performance-critical operations
    const MarketRow* getRow(int index) const;
    const MarketRow* findSymbol(const QString& symbol) const;
    
    // Statistics
    struct ModelStats {
        size_t totalUpdates = 0;
        size_t batchUpdates = 0;
        size_t individualUpdates = 0;
        size_t memoryUsage = 0;
        double avgUpdateTimeMs = 0.0;
    };
    
    ModelStats getStatistics() const;

signals:
    void rowAnimated(int index);
    void countChanged();
    void loadingChanged();
    void filterChanged();
    void sortOrderChanged();
    void dataUpdateStarted();
    void dataUpdateCompleted(int updatedCount);

private:
    // Efficient data storage
    std::vector<std::unique_ptr<MarketRow>> m_rows;
    std::unordered_map<QString, size_t> m_indexMap; // symbol -> index
    
    // Filtered/sorted view
    std::vector<size_t> m_viewIndices;
    bool m_viewDirty = true;
    
    // State
    QString m_filter;
    SortOrder m_sortOrder = SortOrder::None;
    bool m_loading = false;
    
    // Thread safety
    mutable std::shared_mutex m_mutex;
    
    // Statistics
    mutable ModelStats m_stats;
    
    // Helper methods
    void rebuildView();
    bool matchesFilter(const MarketRow& row) const;
    void sortView();
    void updateIndices();
    
    // Efficient update helpers
    void beginBatchUpdate();
    void endBatchUpdate();
    bool updateExistingRow(size_t index, const MarketRow& newData);
    size_t insertNewRow(std::unique_ptr<MarketRow> row);
    void removeRowAt(size_t index);
    
    // Animation support
    void triggerRowAnimation(int viewIndex);
};

// Proxy model for additional filtering/grouping
class MarketProxyModel : public QAbstractListModel {
    Q_OBJECT
public:
    explicit MarketProxyModel(MarketModel* sourceModel, QObject* parent = nullptr);
    
    // Additional filtering options
    void setMinVolume(double volume);
    void setMaxChangePercent(double percent);
    void setWatchlistOnly(bool watchlist);
    void setWatchlistSymbols(const QStringList& symbols);
    
    // QAbstractListModel interface
    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;
    
private slots:
    void sourceDataChanged();
    
private:
    MarketModel* m_sourceModel;
    double m_minVolume = 0.0;
    double m_maxChangePercent = 100.0;
    bool m_watchlistOnly = false;
    QStringList m_watchlistSymbols;
    
    std::vector<int> m_proxyIndices;
    
    void rebuildProxy();
    bool acceptsRow(int sourceRow) const;
};