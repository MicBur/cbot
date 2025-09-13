#include "redisclient.h"
#include <hiredis/hiredis.h>
#include <iostream>

RedisClient::RedisClient(const std::string& host, int port, int db, const std::string& password)
    : m_host(host), m_port(port), m_db(db), m_password(password) {}

RedisClient::~RedisClient() { freeContext(); }

void RedisClient::freeContext() {
    if (m_ctx) {
        redisFree(m_ctx);
        m_ctx = nullptr;
    }
}

bool RedisClient::connect() {
    if (m_ctx) return true;
    m_ctx = redisConnect(m_host.c_str(), m_port);
    if (!m_ctx || m_ctx->err) {
        std::cerr << "Redis connect error: " << (m_ctx ? m_ctx->errstr : "unknown") << std::endl;
        freeContext();
        return false;
    }
    if (!m_password.empty()) {
        if (!authIfNeeded()) return false;
    }
    if (m_db != 0) {
        redisReply* reply = (redisReply*)redisCommand(m_ctx, "SELECT %d", m_db);
        if (!reply || reply->type == REDIS_REPLY_ERROR) {
            if (reply) freeReplyObject(reply);
            std::cerr << "Redis select db failed" << std::endl;
            freeContext();
            return false;
        }
        freeReplyObject(reply);
    }
    return true;
}

bool RedisClient::authIfNeeded() {
    redisReply* reply = (redisReply*)redisCommand(m_ctx, "AUTH %s", m_password.c_str());
    if (!reply) {
        std::cerr << "Redis auth no reply" << std::endl;
        freeContext();
        return false;
    }
    if (reply->type == REDIS_REPLY_ERROR) {
        std::cerr << "Redis auth error: " << reply->str << std::endl;
        freeReplyObject(reply);
        freeContext();
        return false;
    }
    freeReplyObject(reply);
    return true;
}

bool RedisClient::ping() {
    if (!connect()) return false;
    redisReply* reply = (redisReply*)redisCommand(m_ctx, "PING");
    if (!reply) return false;
    bool ok = (reply->type == REDIS_REPLY_STATUS || reply->type == REDIS_REPLY_STRING);
    freeReplyObject(reply);
    return ok;
}

std::optional<std::string> RedisClient::get(const std::string& key) {
    if (!connect()) return std::nullopt;
    redisReply* reply = (redisReply*)redisCommand(m_ctx, "GET %s", key.c_str());
    if (!reply) return std::nullopt;
    if (reply->type == REDIS_REPLY_NIL) {
        freeReplyObject(reply);
        return std::nullopt;
    }
    if (reply->type != REDIS_REPLY_STRING) {
        freeReplyObject(reply);
        return std::nullopt;
    }
    std::string val(reply->str, reply->len);
    freeReplyObject(reply);
    return val;
}
