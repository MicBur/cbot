#pragma once
#include <string>
#include <optional>
#include <unordered_map>
#include <vector>
#include <memory>
#include <chrono>
#include <functional>

struct redisContext; // forward from hiredis
struct redisReply;

// Error codes for better error tracking
enum class RedisError {
    None = 0,
    ConnectionFailed,
    AuthenticationFailed,
    Timeout,
    InvalidCommand,
    NetworkError,
    Unknown
};

// Result type for better error handling
template<typename T>
struct RedisResult {
    std::optional<T> value;
    RedisError error = RedisError::None;
    std::string errorMessage;
    
    bool hasValue() const { return value.has_value(); }
    bool hasError() const { return error != RedisError::None; }
    
    // Convenience constructors
    static RedisResult<T> Success(T val) {
        RedisResult<T> result;
        result.value = std::move(val);
        return result;
    }
    
    static RedisResult<T> Failure(RedisError err, const std::string& msg = "") {
        RedisResult<T> result;
        result.error = err;
        result.errorMessage = msg;
        return result;
    }
};

// Enhanced Redis Client with better error handling and resilience
class RedisClient {
public:
    RedisClient(const std::string& host = "127.0.0.1", int port = 6380, int db = 0, const std::string& password = "");
    ~RedisClient();

    // Configuration
    void setHost(const std::string& h) { if (h != m_host) { freeContext(); m_host = h; } }
    void setPort(int p) { if (p != m_port) { freeContext(); m_port = p; } }
    void setPassword(const std::string& pw) { if (pw != m_password) { freeContext(); m_password = pw; } }
    
    // Connection settings
    void setConnectionTimeout(int milliseconds) { m_connectionTimeoutMs = milliseconds; }
    void setCommandTimeout(int milliseconds) { m_commandTimeoutMs = milliseconds; }
    void setRetryCount(int count) { m_retryCount = count; }
    void setRetryDelay(int milliseconds) { m_retryDelayMs = milliseconds; }
    void setAutoReconnect(bool enable) { m_autoReconnect = enable; }

    // Legacy interface (for backwards compatibility)
    bool connect();
    bool ping();
    std::optional<std::string> get(const std::string& key);
    
    // Enhanced error handling methods
    RedisResult<bool> connectWithResult();
    RedisResult<bool> pingWithResult();
    RedisResult<std::string> getWithResult(const std::string& key);
    
    // Batch operations for efficiency
    RedisResult<std::vector<std::optional<std::string>>> mget(const std::vector<std::string>& keys);
    
    // Connection state
    bool isConnected() const;
    RedisError getLastError() const { return m_lastError; }
    const std::string& getLastErrorMessage() const { return m_lastErrorMessage; }
    
    // Statistics
    size_t getRetryCount() const { return m_totalRetries; }
    size_t getFailedCommands() const { return m_failedCommands; }
    size_t getSuccessfulCommands() const { return m_successfulCommands; }
    std::chrono::milliseconds getLastCommandDuration() const { return m_lastCommandDuration; }
    double getAverageLatency() const;
    
    // Connection pool support (future enhancement)
    void releaseConnection() { freeContext(); }
    bool reconnect() { freeContext(); return connect(); }

private:
    std::string m_host;
    int m_port;
    int m_db;
    std::string m_password;
    redisContext* m_ctx {nullptr};
    
    // Timeouts and retry settings
    int m_connectionTimeoutMs = 5000;
    int m_commandTimeoutMs = 3000;
    int m_retryCount = 3;
    int m_retryDelayMs = 100;
    bool m_autoReconnect = true;
    
    // Error tracking
    mutable RedisError m_lastError = RedisError::None;
    mutable std::string m_lastErrorMessage;
    
    // Statistics
    size_t m_totalRetries = 0;
    size_t m_failedCommands = 0;
    size_t m_successfulCommands = 0;
    mutable std::chrono::milliseconds m_lastCommandDuration{0};
    mutable std::chrono::milliseconds m_totalCommandDuration{0};
    
    void freeContext();
    bool authIfNeeded();
    bool selectDb();
    bool executeWithRetry(std::function<bool()> operation);
    void setError(RedisError error, const std::string& message) const;
    void updateStats(bool success, std::chrono::milliseconds duration) const;
    
    // Helper to check and auto-reconnect if needed
    bool ensureConnected();
    
    // Template helper for command execution
    template<typename T>
    RedisResult<T> executeCommand(std::function<RedisResult<T>()> command);
};

// Connection Pool for improved performance
class RedisConnectionPool {
public:
    RedisConnectionPool(const std::string& host, int port, int db, const std::string& password, size_t poolSize = 5);
    ~RedisConnectionPool();
    
    std::shared_ptr<RedisClient> acquire();
    void release(std::shared_ptr<RedisClient> client);
    
    size_t getPoolSize() const { return m_poolSize; }
    size_t getAvailableConnections() const { return m_available.size(); }
    
private:
    std::string m_host;
    int m_port;
    int m_db;
    std::string m_password;
    size_t m_poolSize;
    
    std::vector<std::shared_ptr<RedisClient>> m_available;
    std::vector<std::shared_ptr<RedisClient>> m_inUse;
    mutable std::mutex m_mutex;
    std::condition_variable m_cv;
    
    std::shared_ptr<RedisClient> createConnection();
};