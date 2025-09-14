// Enhanced Redis Client Implementation with robust error handling
#include "redisclient_improved.h"
#include <iostream>
#include <thread>
#include <mutex>
#include <condition_variable>

#ifndef REDIS_STUB
#if defined(HIREDIS_VENDORED)
#include <hiredis.h>
#else
#include <hiredis/hiredis.h>
#endif
#endif

// Helper function to get error message
static std::string getRedisErrorString(redisContext* ctx) {
#ifndef REDIS_STUB
    if (!ctx) return "Context is null";
    if (ctx->err) return std::string(ctx->errstr);
    return "Unknown error";
#else
    return "Redis stub mode";
#endif
}

RedisClient::RedisClient(const std::string& host, int port, int db, const std::string& password)
    : m_host(host), m_port(port), m_db(db), m_password(password) {}

RedisClient::~RedisClient() { 
    freeContext(); 
}

void RedisClient::freeContext() {
#ifndef REDIS_STUB
    if (m_ctx) { 
        redisFree(m_ctx); 
        m_ctx = nullptr; 
    }
#else
    m_ctx = nullptr;
#endif
}

bool RedisClient::connect() {
    auto result = connectWithResult();
    return result.hasValue() && result.value.value_or(false);
}

RedisResult<bool> RedisClient::connectWithResult() {
#ifdef REDIS_STUB
    setError(RedisError::ConnectionFailed, "Redis stub mode - no live connection");
    return RedisResult<bool>::Failure(RedisError::ConnectionFailed, "Redis stub mode");
#else
    if (m_ctx && !m_ctx->err) {
        return RedisResult<bool>::Success(true);
    }
    
    // Free any existing context
    freeContext();
    
    // Connect with timeout
    struct timeval timeout = { m_connectionTimeoutMs / 1000, (m_connectionTimeoutMs % 1000) * 1000 };
    m_ctx = redisConnectWithTimeout(m_host.c_str(), m_port, timeout);
    
    if (!m_ctx) {
        setError(RedisError::ConnectionFailed, "Failed to allocate redis context");
        return RedisResult<bool>::Failure(RedisError::ConnectionFailed, "Failed to allocate redis context");
    }
    
    if (m_ctx->err) {
        std::string errMsg = getRedisErrorString(m_ctx);
        setError(RedisError::ConnectionFailed, errMsg);
        freeContext();
        return RedisResult<bool>::Failure(RedisError::ConnectionFailed, errMsg);
    }
    
    // Set command timeout
    struct timeval cmdTimeout = { m_commandTimeoutMs / 1000, (m_commandTimeoutMs % 1000) * 1000 };
    redisSetTimeout(m_ctx, cmdTimeout);
    
    // Authenticate if needed
    if (!m_password.empty() && !authIfNeeded()) {
        return RedisResult<bool>::Failure(m_lastError, m_lastErrorMessage);
    }
    
    // Select database
    if (m_db != 0 && !selectDb()) {
        return RedisResult<bool>::Failure(m_lastError, m_lastErrorMessage);
    }
    
    setError(RedisError::None, "");
    return RedisResult<bool>::Success(true);
#endif
}

bool RedisClient::authIfNeeded() {
#ifdef REDIS_STUB
    return false;
#else
    if (!m_ctx) return false;
    
    redisReply* reply = (redisReply*)redisCommand(m_ctx, "AUTH %s", m_password.c_str());
    if (!reply) {
        setError(RedisError::AuthenticationFailed, "No reply from AUTH command");
        freeContext();
        return false;
    }
    
    bool success = (reply->type != REDIS_REPLY_ERROR);
    if (!success) {
        setError(RedisError::AuthenticationFailed, std::string(reply->str));
    }
    
    freeReplyObject(reply);
    return success;
#endif
}

bool RedisClient::selectDb() {
#ifdef REDIS_STUB
    return false;
#else
    if (!m_ctx) return false;
    
    redisReply* reply = (redisReply*)redisCommand(m_ctx, "SELECT %d", m_db);
    if (!reply) {
        setError(RedisError::InvalidCommand, "No reply from SELECT command");
        freeContext();
        return false;
    }
    
    bool success = (reply->type != REDIS_REPLY_ERROR);
    if (!success) {
        setError(RedisError::InvalidCommand, std::string(reply->str));
    }
    
    freeReplyObject(reply);
    return success;
#endif
}

bool RedisClient::ping() {
    auto result = pingWithResult();
    return result.hasValue() && result.value.value_or(false);
}

RedisResult<bool> RedisClient::pingWithResult() {
#ifdef REDIS_STUB
    setError(RedisError::ConnectionFailed, "Redis stub mode");
    return RedisResult<bool>::Failure(RedisError::ConnectionFailed, "Redis stub mode");
#else
    auto start = std::chrono::steady_clock::now();
    
    if (!ensureConnected()) {
        return RedisResult<bool>::Failure(m_lastError, m_lastErrorMessage);
    }
    
    redisReply* reply = (redisReply*)redisCommand(m_ctx, "PING");
    auto end = std::chrono::steady_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end - start);
    
    if (!reply) {
        updateStats(false, duration);
        if (m_ctx && m_ctx->err) {
            // Connection error - try to reconnect if auto-reconnect is enabled
            if (m_autoReconnect) {
                freeContext();
                if (connect()) {
                    // Retry the ping
                    reply = (redisReply*)redisCommand(m_ctx, "PING");
                }
            }
        }
        
        if (!reply) {
            setError(RedisError::NetworkError, "No reply from PING command");
            return RedisResult<bool>::Failure(RedisError::NetworkError, "No reply from PING command");
        }
    }
    
    bool success = (reply->type == REDIS_REPLY_STATUS || reply->type == REDIS_REPLY_STRING);
    freeReplyObject(reply);
    
    updateStats(success, duration);
    
    if (success) {
        setError(RedisError::None, "");
        return RedisResult<bool>::Success(true);
    } else {
        setError(RedisError::InvalidCommand, "Unexpected PING response");
        return RedisResult<bool>::Failure(RedisError::InvalidCommand, "Unexpected PING response");
    }
#endif
}

std::optional<std::string> RedisClient::get(const std::string& key) {
    auto result = getWithResult(key);
    return result.value;
}

RedisResult<std::string> RedisClient::getWithResult(const std::string& key) {
#ifdef REDIS_STUB
    setError(RedisError::ConnectionFailed, "Redis stub mode");
    return RedisResult<std::string>::Failure(RedisError::ConnectionFailed, "Redis stub mode");
#else
    auto start = std::chrono::steady_clock::now();
    
    if (!ensureConnected()) {
        return RedisResult<std::string>::Failure(m_lastError, m_lastErrorMessage);
    }
    
    redisReply* reply = (redisReply*)redisCommand(m_ctx, "GET %s", key.c_str());
    auto end = std::chrono::steady_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end - start);
    
    if (!reply) {
        updateStats(false, duration);
        setError(RedisError::NetworkError, "No reply from GET command");
        return RedisResult<std::string>::Failure(RedisError::NetworkError, "No reply from GET command");
    }
    
    if (reply->type == REDIS_REPLY_NIL) {
        freeReplyObject(reply);
        updateStats(true, duration);
        setError(RedisError::None, "");
        return RedisResult<std::string>::Failure(RedisError::None, "Key not found");
    }
    
    if (reply->type != REDIS_REPLY_STRING) {
        freeReplyObject(reply);
        updateStats(false, duration);
        setError(RedisError::InvalidCommand, "Unexpected GET response type");
        return RedisResult<std::string>::Failure(RedisError::InvalidCommand, "Unexpected GET response type");
    }
    
    std::string value(reply->str, reply->len);
    freeReplyObject(reply);
    
    updateStats(true, duration);
    setError(RedisError::None, "");
    return RedisResult<std::string>::Success(value);
#endif
}

RedisResult<std::vector<std::optional<std::string>>> RedisClient::mget(const std::vector<std::string>& keys) {
#ifdef REDIS_STUB
    setError(RedisError::ConnectionFailed, "Redis stub mode");
    return RedisResult<std::vector<std::optional<std::string>>>::Failure(RedisError::ConnectionFailed, "Redis stub mode");
#else
    if (keys.empty()) {
        return RedisResult<std::vector<std::optional<std::string>>>::Success({});
    }
    
    auto start = std::chrono::steady_clock::now();
    
    if (!ensureConnected()) {
        return RedisResult<std::vector<std::optional<std::string>>>::Failure(m_lastError, m_lastErrorMessage);
    }
    
    // Build MGET command
    std::vector<const char*> argv;
    std::vector<size_t> argvlen;
    
    argv.push_back("MGET");
    argvlen.push_back(4);
    
    for (const auto& key : keys) {
        argv.push_back(key.c_str());
        argvlen.push_back(key.length());
    }
    
    redisReply* reply = (redisReply*)redisCommandArgv(m_ctx, static_cast<int>(argv.size()), argv.data(), argvlen.data());
    auto end = std::chrono::steady_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end - start);
    
    if (!reply) {
        updateStats(false, duration);
        setError(RedisError::NetworkError, "No reply from MGET command");
        return RedisResult<std::vector<std::optional<std::string>>>::Failure(RedisError::NetworkError, "No reply from MGET command");
    }
    
    if (reply->type != REDIS_REPLY_ARRAY) {
        freeReplyObject(reply);
        updateStats(false, duration);
        setError(RedisError::InvalidCommand, "Unexpected MGET response type");
        return RedisResult<std::vector<std::optional<std::string>>>::Failure(RedisError::InvalidCommand, "Unexpected MGET response type");
    }
    
    std::vector<std::optional<std::string>> results;
    results.reserve(reply->elements);
    
    for (size_t i = 0; i < reply->elements; ++i) {
        if (reply->element[i]->type == REDIS_REPLY_STRING) {
            results.emplace_back(std::string(reply->element[i]->str, reply->element[i]->len));
        } else {
            results.emplace_back(std::nullopt);
        }
    }
    
    freeReplyObject(reply);
    updateStats(true, duration);
    setError(RedisError::None, "");
    
    return RedisResult<std::vector<std::optional<std::string>>>::Success(results);
#endif
}

bool RedisClient::isConnected() const {
#ifdef REDIS_STUB
    return false;
#else
    return m_ctx && !m_ctx->err;
#endif
}

bool RedisClient::ensureConnected() {
    if (isConnected()) {
        return true;
    }
    
    if (m_autoReconnect) {
        return connect();
    }
    
    setError(RedisError::ConnectionFailed, "Not connected to Redis");
    return false;
}

void RedisClient::setError(RedisError error, const std::string& message) const {
    m_lastError = error;
    m_lastErrorMessage = message;
}

void RedisClient::updateStats(bool success, std::chrono::milliseconds duration) const {
    m_lastCommandDuration = duration;
    m_totalCommandDuration += duration;
    
    if (success) {
        m_successfulCommands++;
    } else {
        m_failedCommands++;
    }
}

double RedisClient::getAverageLatency() const {
    size_t totalCommands = m_successfulCommands + m_failedCommands;
    if (totalCommands == 0) return 0.0;
    
    return static_cast<double>(m_totalCommandDuration.count()) / static_cast<double>(totalCommands);
}

bool RedisClient::executeWithRetry(std::function<bool()> operation) {
    for (int attempt = 0; attempt <= m_retryCount; ++attempt) {
        if (operation()) {
            return true;
        }
        
        if (attempt < m_retryCount) {
            m_totalRetries++;
            std::this_thread::sleep_for(std::chrono::milliseconds(m_retryDelayMs));
        }
    }
    
    return false;
}

// Connection Pool Implementation
RedisConnectionPool::RedisConnectionPool(const std::string& host, int port, int db, const std::string& password, size_t poolSize)
    : m_host(host), m_port(port), m_db(db), m_password(password), m_poolSize(poolSize) {
    
    // Pre-create connections
    for (size_t i = 0; i < poolSize; ++i) {
        auto client = createConnection();
        if (client && client->connect()) {
            m_available.push_back(client);
        }
    }
}

RedisConnectionPool::~RedisConnectionPool() {
    std::lock_guard<std::mutex> lock(m_mutex);
    m_available.clear();
    m_inUse.clear();
}

std::shared_ptr<RedisClient> RedisConnectionPool::createConnection() {
    auto client = std::make_shared<RedisClient>(m_host, m_port, m_db, m_password);
    client->setAutoReconnect(true);
    return client;
}

std::shared_ptr<RedisClient> RedisConnectionPool::acquire() {
    std::unique_lock<std::mutex> lock(m_mutex);
    
    // Wait for an available connection
    m_cv.wait(lock, [this]() { return !m_available.empty(); });
    
    auto client = m_available.back();
    m_available.pop_back();
    m_inUse.push_back(client);
    
    // Ensure connection is still valid
    if (!client->isConnected()) {
        client->reconnect();
    }
    
    return client;
}

void RedisConnectionPool::release(std::shared_ptr<RedisClient> client) {
    std::lock_guard<std::mutex> lock(m_mutex);
    
    // Remove from in-use list
    auto it = std::find(m_inUse.begin(), m_inUse.end(), client);
    if (it != m_inUse.end()) {
        m_inUse.erase(it);
        m_available.push_back(client);
        m_cv.notify_one();
    }
}