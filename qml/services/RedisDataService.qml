import QtQuick 2.15
import Frontend 1.0

QtObject {
    id: dataService
    
    // Redis connection properties
    property string redisHost: "127.0.0.1"
    property int redisPort: 6380
    property string redisPassword: ""
    property bool connected: redisClient.connected
    property string connectionStatus: redisClient.connected ? "Connected" : "Disconnected"
    
    // Direct Redis client
    RedisClient {
        id: redisClient
        host: dataService.redisHost
        port: dataService.redisPort
        password: dataService.redisPassword
        
        onConnectedChanged: {
            if (connected) {
                console.log("✅ Redis connected successfully")
                loadInitialData()
            } else {
                console.log("❌ Redis disconnected")
            }
        }
        
        Component.onCompleted: {
            connectToRedis()
        }
    }
    
    // Data models
    property var marketData: marketModel
    property var portfolioData: portfolioModel
    property var ordersData: ordersModel
    property var notificationsData: notificationsModel
    property var statusData: statusModel
    
    // Auto-refresh timer
    Timer {
        id: refreshTimer
        interval: 2000 // 2 seconds
        running: dataService.connected
        repeat: true
        onTriggered: refreshData()
    }
    
    // Load initial data from Redis
    function loadInitialData() {
        if (!redisClient.connected) return
        
        console.log("📊 Loading initial data from Redis...")
        
        // Load market data
        refreshMarketData()
        
        // Load portfolio data
        refreshPortfolioData()
        
        // Load orders data
        refreshOrdersData()
        
        // Load notifications
        refreshNotifications()
        
        // Load status
        refreshStatus()
    }
    
    // Refresh all data
    function refreshData() {
        if (!redisClient.connected) return
        
        refreshMarketData()
        refreshPortfolioData() 
        refreshOrdersData()
        refreshStatus()
    }
    
    function refreshMarketData() {
        let keys = redisClient.keys("market:*")
        let newData = []
        
        for (let key of keys) {
            let data = redisClient.hgetall(key)
            if (Object.keys(data).length > 0) {
                newData.push({
                    symbol: data.symbol || "",
                    price: parseFloat(data.price || 0),
                    change: parseFloat(data.change || 0),
                    changePercent: parseFloat(data.changePercent || 0),
                    volume: parseInt(data.volume || 0),
                    high: parseFloat(data.high || 0),
                    low: parseFloat(data.low || 0)
                })
            }
        }
        
        // Update market model
        marketModel.clear()
        for (let item of newData) {
            marketModel.append(item)
        }
    }
    
    function refreshPortfolioData() {
        let keys = redisClient.keys("portfolio:*")
        let newData = []
        
        for (let key of keys) {
            let data = redisClient.hgetall(key)
            if (Object.keys(data).length > 0) {
                newData.push({
                    ticker: data.ticker || "",
                    qty: parseFloat(data.qty || 0),
                    avgPrice: parseFloat(data.avgPrice || 0),
                    side: data.side || "long"
                })
            }
        }
        
        // Update portfolio model
        portfolioModel.clear()
        for (let item of newData) {
            portfolioModel.append(item)
        }
    }
    
    function refreshOrdersData() {
        let keys = redisClient.keys("order:*")
        let newData = []
        
        for (let key of keys) {
            let data = redisClient.hgetall(key)
            if (Object.keys(data).length > 0) {
                newData.push({
                    id: data.id || "",
                    ticker: data.ticker || "",
                    side: data.side || "",
                    qty: parseFloat(data.qty || 0),
                    price: parseFloat(data.price || 0),
                    status: data.status || "",
                    timestamp: data.timestamp || ""
                })
            }
        }
        
        // Update orders model
        ordersModel.clear()
        for (let item of newData) {
            ordersModel.append(item)
        }
    }
    
    function refreshNotifications() {
        let keys = redisClient.keys("notification:*")
        let newData = []
        
        for (let key of keys) {
            let data = redisClient.hgetall(key)
            if (Object.keys(data).length > 0) {
                newData.push({
                    id: data.id || "",
                    title: data.title || "",
                    message: data.message || "",
                    type: data.type || "info",
                    timestamp: data.timestamp || "",
                    read: data.read === "true"
                })
            }
        }
        
        // Update notifications model (newest first)
        notificationsModel.clear()
        newData.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp))
        for (let item of newData) {
            notificationsModel.append(item)
        }
    }
    
    function refreshStatus() {
        let statusData = redisClient.hgetall("system:status")
        
        if (Object.keys(statusData).length > 0) {
            statusModel.postgresConnected = statusData.postgres === "true"
            statusModel.workerRunning = statusData.worker === "true"
            statusModel.alpacaApiActive = statusData.alpaca === "true"
            statusModel.grokApiActive = statusData.grok === "true"
            statusModel.lastUpdate = new Date().toISOString()
        }
    }
    
    // Market Model
    property var marketModel: ListModel {
        id: marketModel
    }
    
    // Portfolio Model
    property var portfolioModel: ListModel {
        id: portfolioModel
        
        function getTotalValue() {
            let total = 0
            for (let i = 0; i < count; i++) {
                let item = get(i)
                total += (item.qty || 0) * (item.avgPrice || 0)
            }
            return total
        }
    }
    
    // Orders Model
    property var ordersModel: ListModel {
        id: ordersModel
    }
    
    // Notifications Model
    property var notificationsModel: ListModel {
        id: notificationsModel
        
        function markRead(index) {
            if (index >= 0 && index < count) {
                let item = get(index)
                setProperty(index, "read", true)
                
                // Update in Redis
                if (redisClient.connected && item.id) {
                    // This would require a SET command implementation
                    console.log("Marking notification as read:", item.id)
                }
            }
        }
        
        function markAllRead() {
            for (let i = 0; i < count; i++) {
                setProperty(i, "read", true)
            }
        }
        
        function getUnreadCount() {
            let unread = 0
            for (let i = 0; i < count; i++) {
                if (!get(i).read) {
                    unread++
                }
            }
            return unread
        }
    }
    
    // Status Model
    property var statusModel: QtObject {
        id: statusModel
        
        property bool postgresConnected: false
        property bool workerRunning: false
        property bool alpacaApiActive: false
        property bool grokApiActive: false
        property string lastUpdate: ""
    }
    
    // Connection management
    function reconnect() {
        console.log("🔄 Reconnecting to Redis...")
        redisClient.connectToRedis()
    }
    
    function disconnect() {
        console.log("📴 Disconnecting from Redis...")
        redisClient.disconnect()
    }
    
    // Component initialization
    Component.onCompleted: {
        console.log("🚀 RedisDataService initialized")
        console.log("Redis Host:", redisHost + ":" + redisPort)
    }
}