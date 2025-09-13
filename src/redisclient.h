#pragma once
#include <string>
#include <optional>
#include <unordered_map>
#include <vector>
#include <memory>

struct redisContext; // forward from hiredis
struct redisReply;

// Very small RAII wrapper for hiredis context & replies
class RedisClient {
public:
    RedisClient(const std::string& host = "127.0.0.1", int port = 6380, int db = 0, const std::string& password = "");
    ~RedisClient();

    bool connect();
    bool ping();
    void setHost(const std::string& h) { if (h != m_host) { freeContext(); m_host = h; } }
    void setPort(int p) { if (p != m_port) { freeContext(); m_port = p; } }
    void setPassword(const std::string& pw) { if (pw != m_password) { freeContext(); m_password = pw; } }

    // Returns raw string value (nullptr if not found / error)
    std::optional<std::string> get(const std::string& key);

private:
    std::string m_host;
    int m_port;
    int m_db;
    std::string m_password;
    redisContext* m_ctx {nullptr};

    void freeContext();
    bool authIfNeeded();
};
