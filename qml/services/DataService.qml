import QtQuick 2.15
import QtWebSockets 1.15

QtObject {
    id: dataService
    
    // Connection properties
    property string redisHost: "127.0.0.1"
    property int redisPort: 6380
    property string redisPassword: ""
    property bool connected: false
    property string connectionStatus: "Disconnected"
    
    // Data models
    property var marketData: marketModel
    property var portfolioData: portfolioModel
    property var ordersData: ordersModel
    property var notificationsData: notificationsModel
    property var statusData: statusModel
    
    // WebSocket connection for real-time data
    WebSocket {
        id: websocket
        url: "ws://" + dataService.redisHost + ":" + (dataService.redisPort + 1000) // Assuming WebSocket on port+1000
        active: true
        
        onStatusChanged: {
            switch(status) {
                case WebSocket.Connecting:
                    dataService.connectionStatus = "Connecting..."
                    dataService.connected = false
                    break
                case WebSocket.Open:
                    dataService.connectionStatus = "Connected"
                    dataService.connected = true
                    console.log("WebSocket connected to:", url)
                    // Subscribe to data streams
                    sendTextMessage(JSON.stringify({
                        action: "subscribe",
                        channels: ["market", "portfolio", "orders", "notifications", "status"]
                    }))
                    break
                case WebSocket.Closed:
                    dataService.connectionStatus = "Disconnected"
                    dataService.connected = false
                    console.log("WebSocket disconnected")
                    break
                case WebSocket.Error:
                    dataService.connectionStatus = "Error"
                    dataService.connected = false
                    console.error("WebSocket error:", errorString)
                    break
            }
        }
        
        onTextMessageReceived: function(message) {
            try {
                let data = JSON.parse(message)
                handleIncomingData(data)
            } catch(e) {
                console.error("Failed to parse WebSocket message:", e, message)
            }
        }
    }
    
    // HTTP fallback for initial data loading
    function loadInitialData() {
        // Load market data
        let xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        let data = JSON.parse(xhr.responseText)
                        marketModel.loadFromJson(data)
                    } catch(e) {
                        console.error("Failed to parse market data:", e)
                    }
                }
            }
        }
        xhr.open("GET", "http://" + redisHost + ":8080/api/market")
        xhr.send()
        
        // Load portfolio data
        loadPortfolioData()
        loadOrdersData()
        loadNotificationsData()
    }
    
    function loadPortfolioData() {
        let xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                try {
                    let data = JSON.parse(xhr.responseText)
                    portfolioModel.loadFromJson(data)
                } catch(e) {
                    console.error("Failed to parse portfolio data:", e)
                }
            }
        }
        xhr.open("GET", "http://" + redisHost + ":8080/api/portfolio")
        xhr.send()
    }
    
    function loadOrdersData() {
        let xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                try {
                    let data = JSON.parse(xhr.responseText)
                    ordersModel.loadFromJson(data)
                } catch(e) {
                    console.error("Failed to parse orders data:", e)
                }
            }
        }
        xhr.open("GET", "http://" + redisHost + ":8080/api/orders")
        xhr.send()
    }
    
    function loadNotificationsData() {
        let xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                try {
                    let data = JSON.parse(xhr.responseText)
                    notificationsModel.loadFromJson(data)
                } catch(e) {
                    console.error("Failed to parse notifications data:", e)
                }
            }
        }
        xhr.open("GET", "http://" + redisHost + ":8080/api/notifications")
        xhr.send()
    }
    
    // Handle incoming real-time data
    function handleIncomingData(data) {
        switch(data.channel) {
            case "market":
                marketModel.updateFromWebSocket(data.payload)
                break
            case "portfolio":
                portfolioModel.updateFromWebSocket(data.payload)
                break
            case "orders":
                ordersModel.updateFromWebSocket(data.payload)
                break
            case "notifications":
                notificationsModel.addNotification(data.payload)
                break
            case "status":
                statusModel.updateStatus(data.payload)
                break
            default:
                console.log("Unknown data channel:", data.channel)
        }
    }
    
    // Reconnection timer
    Timer {
        id: reconnectTimer
        interval: 5000
        repeat: true
        running: !dataService.connected
        onTriggered: {
            if (!websocket.active) {
                console.log("Attempting to reconnect...")
                websocket.active = true
            }
        }
    }
    
    // Initialize on component completion
    Component.onCompleted: {
        console.log("DataService initialized")
        loadInitialData()
    }
    
    // Market Model
    property var marketModel: ListModel {
        id: marketModel
        
        function loadFromJson(data) {
            clear()
            if (Array.isArray(data)) {
                for (let item of data) {
                    append(item)
                }
            }
        }
        
        function updateFromWebSocket(data) {
            if (data.symbol) {
                // Find existing item or create new one
                for (let i = 0; i < count; i++) {
                    if (get(i).symbol === data.symbol) {
                        // Update existing
                        for (let key in data) {
                            setProperty(i, key, data[key])
                        }
                        return
                    }
                }
                // Add new item if not found
                append(data)
            }
        }
    }
    
    // Portfolio Model
    property var portfolioModel: ListModel {
        id: portfolioModel
        
        function loadFromJson(data) {
            clear()
            if (Array.isArray(data)) {
                for (let item of data) {
                    append(item)
                }
            }
        }
        
        function updateFromWebSocket(data) {
            if (data.ticker) {
                for (let i = 0; i < count; i++) {
                    if (get(i).ticker === data.ticker) {
                        for (let key in data) {
                            setProperty(i, key, data[key])
                        }
                        return
                    }
                }
                append(data)
            }
        }
        
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
        
        function loadFromJson(data) {
            clear()
            if (Array.isArray(data)) {
                for (let item of data) {
                    append(item)
                }
            }
        }
        
        function updateFromWebSocket(data) {
            if (data.id) {
                for (let i = 0; i < count; i++) {
                    if (get(i).id === data.id) {
                        for (let key in data) {
                            setProperty(i, key, data[key])
                        }
                        return
                    }
                }
                append(data)
            }
        }
    }
    
    // Notifications Model
    property var notificationsModel: ListModel {
        id: notificationsModel
        
        function loadFromJson(data) {
            clear()
            if (Array.isArray(data)) {
                for (let item of data) {
                    append(item)
                }
            }
        }
        
        function addNotification(data) {
            // Add timestamp if not present
            if (!data.timestamp) {
                data.timestamp = new Date().toISOString()
            }
            if (!data.read) {
                data.read = false
            }
            
            // Insert at beginning for newest first
            insert(0, data)
            
            // Limit to 100 notifications
            while (count > 100) {
                remove(count - 1)
            }
        }
        
        function markRead(index) {
            if (index >= 0 && index < count) {
                setProperty(index, "read", true)
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
        
        function updateStatus(data) {
            if (data.hasOwnProperty("postgresConnected")) {
                postgresConnected = data.postgresConnected
            }
            if (data.hasOwnProperty("workerRunning")) {
                workerRunning = data.workerRunning
            }
            if (data.hasOwnProperty("alpacaApiActive")) {
                alpacaApiActive = data.alpacaApiActive
            }
            if (data.hasOwnProperty("grokApiActive")) {
                grokApiActive = data.grokApiActive
            }
            lastUpdate = new Date().toISOString()
        }
    }
}