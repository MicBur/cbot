#pragma once
#include "basemodel.h"
#include <vector>
#include <memory>
#include <unordered_map>
#include <QTimer>

// Forward declarations
class MarketDataProvider;
class MarketDataValidator;

/**
 * @brief Enhanced market data structure with additional fields
 */
struct MarketData {
    QString symbol;
    double price = 0.0;
    double change = 0.0;
    double changePercent = 0.0;
    double volume = 0.0;
    double dayHigh = 0.0;
    double dayLow = 0.0;
    double previousClose = 0.0;
    double bid = 0.0;
    double ask = 0.0;
    double spread = 0.0;
    qint64 lastUpdateTime = 0;
    qint64 marketCap = 0;
    int direction = 0; // -1: down, 0: unchanged, 1: up
    bool isHalted = false;
    QString exchange;
    
    // Technical indicators (optional)
    double rsi = 0.0;
    double movingAvg50 = 0.0;
    double movingAvg200 = 0.0;
    
    // Comparison operators for sorting
    bool operator<(const MarketData& other) const { return symbol < other.symbol; }
    bool operator==(const MarketData& other) const { return symbol == other.symbol; }
};

/**
 * @brief Refactored Market Model with clean architecture
 */
class MarketModelRefactored : public BaseModel, public IFilterable, public ISortable, public IRealTimeUpdatable {
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)
    Q_PROPERTY(QString filter READ filter WRITE setFilter NOTIFY filterChanged)
    Q_PROPERTY(double totalMarketCap READ totalMarketCap NOTIFY marketCapChanged)
    Q_PROPERTY(int gainersCount READ gainersCount NOTIFY statsChanged)
    Q_PROPERTY(int losersCount READ losersCount NOTIFY statsChanged)
    
public:
    enum Roles {
        SymbolRole = Qt::UserRole + 1,
        PriceRole,
        ChangeRole,
        ChangePercentRole,
        VolumeRole,
        DirectionRole,
        DayHighRole,
        DayLowRole,
        BidRole,
        AskRole,
        SpreadRole,
        MarketCapRole,
        IsHaltedRole,
        ExchangeRole,
        RSIRole,
        MA50Role,
        MA200Role,
        LastUpdateRole
    };
    Q_ENUM(Roles)
    
    enum class SortColumn {
        Symbol = 0,
        Price,
        Change,
        ChangePercent,
        Volume,
        MarketCap
    };
    Q_ENUM(SortColumn)
    
    explicit MarketModelRefactored(QObject* parent = nullptr);
    ~MarketModelRefactored() override;
    
    // QAbstractListModel interface
    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;
    
    // BaseModel interface
    void updateFromJsonObject(const QJsonObject& obj) override;
    void updateFromJsonArray(const QJsonArray& array) override;
    bool validateJsonData(const QJsonDocument& doc) const override;
    
    // IFilterable interface
    void setFilter(const QString& filter) override;
    QString filter() const override { return m_filter; }
    void clearFilter() override { setFilter(QString()); }
    
    // ISortable interface
    void setSortColumn(int column) override;
    void setSortOrder(SortOrder order) override;
    int sortColumn() const override { return static_cast<int>(m_sortColumn); }
    SortOrder sortOrder() const override { return m_sortOrder; }
    
    // IRealTimeUpdatable interface
    void enableRealTimeUpdates(bool enable) override;
    bool realTimeUpdatesEnabled() const override { return m_realTimeEnabled; }
    void setUpdateInterval(int milliseconds) override;
    int updateInterval() const override { return m_updateInterval; }
    
    // Advanced features
    void setDataProvider(std::shared_ptr<MarketDataProvider> provider);
    void setValidator(std::shared_ptr<MarketDataValidator> validator);
    
    // Bulk operations
    void updateSymbols(const QVector<MarketData>& data);
    void removeSymbols(const QStringList& symbols);
    void clearAll();
    
    // Data access
    const MarketData* findSymbol(const QString& symbol) const;
    QVector<MarketData> getTopGainers(int count = 10) const;
    QVector<MarketData> getTopLosers(int count = 10) const;
    QVector<MarketData> getTopVolume(int count = 10) const;
    
    // Statistics
    double totalMarketCap() const;
    int gainersCount() const;
    int losersCount() const;
    double averageChangePercent() const;
    
    // Watchlist support
    void addToWatchlist(const QString& symbol);
    void removeFromWatchlist(const QString& symbol);
    bool isInWatchlist(const QString& symbol) const;
    QStringList watchlist() const { return m_watchlist; }
    
    // Export functionality
    QJsonArray toJsonArray() const;
    bool exportToFile(const QString& filename) const;
    
signals:
    void countChanged();
    void filterChanged();
    void sortChanged();
    void marketCapChanged();
    void statsChanged();
    void symbolUpdated(const QString& symbol);
    void symbolAdded(const QString& symbol);
    void symbolRemoved(const QString& symbol);
    void watchlistChanged();
    void realTimeUpdateReceived(const QString& symbol);
    
private slots:
    void onRealTimeUpdate();
    
private:
    // Data storage
    std::vector<std::unique_ptr<MarketData>> m_data;
    std::unordered_map<QString, size_t> m_symbolIndex;
    
    // View management
    std::vector<size_t> m_filteredIndices;
    QString m_filter;
    SortColumn m_sortColumn = SortColumn::Symbol;
    SortOrder m_sortOrder = SortOrder::Ascending;
    bool m_viewNeedsUpdate = true;
    
    // Watchlist
    QStringList m_watchlist;
    
    // Real-time updates
    bool m_realTimeEnabled = false;
    int m_updateInterval = 5000;
    QTimer* m_updateTimer = nullptr;
    
    // External components
    std::shared_ptr<MarketDataProvider> m_dataProvider;
    std::shared_ptr<MarketDataValidator> m_validator;
    
    // Statistics cache
    mutable double m_cachedMarketCap = 0.0;
    mutable int m_cachedGainers = 0;
    mutable int m_cachedLosers = 0;
    mutable bool m_statsCacheValid = false;
    
    // Helper methods
    void rebuildView();
    void updateView();
    bool matchesFilter(const MarketData& data) const;
    void sortData();
    void updateStatistics() const;
    void invalidateStatsCache() { m_statsCacheValid = false; }
    
    // Update helpers
    bool updateExistingSymbol(const QString& symbol, const MarketData& data);
    void insertNewSymbol(std::unique_ptr<MarketData> data);
    void removeSymbolAt(size_t index);
    
    // Validation
    bool validateMarketData(const MarketData& data) const;
};

/**
 * @brief Interface for market data providers
 */
class MarketDataProvider : public QObject {
    Q_OBJECT
public:
    virtual ~MarketDataProvider() = default;
    
    virtual void requestSnapshot() = 0;
    virtual void requestSymbol(const QString& symbol) = 0;
    virtual void subscribeToUpdates(const QStringList& symbols) = 0;
    virtual void unsubscribeFromUpdates(const QStringList& symbols) = 0;
    
signals:
    void dataReceived(const QVector<MarketData>& data);
    void symbolDataReceived(const QString& symbol, const MarketData& data);
    void error(const QString& error);
};

/**
 * @brief Market data validator
 */
class MarketDataValidator {
public:
    virtual ~MarketDataValidator() = default;
    
    virtual bool validate(const MarketData& data) const {
        // Basic validation
        if (data.symbol.isEmpty()) return false;
        if (data.price < 0) return false;
        if (data.volume < 0) return false;
        if (data.bid > data.ask && data.bid > 0 && data.ask > 0) return false;
        return true;
    }
    
    virtual QString validationError() const { return m_lastError; }
    
protected:
    mutable QString m_lastError;
};