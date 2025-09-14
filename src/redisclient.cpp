// Redis Client Implementation (real or stub depending on REDIS_STUB)
#include "redisclient.h"
#include <iostream>

#ifndef REDIS_STUB
#if defined(HIREDIS_VENDORED)
#include <hiredis.h>
#else
#include <hiredis/hiredis.h>
#endif
#endif

RedisClient::RedisClient(const std::string& host, int port, int db, const std::string& password)
    : m_host(host), m_port(port), m_db(db), m_password(password) {}

RedisClient::~RedisClient() { freeContext(); }

void RedisClient::freeContext() {
#ifndef REDIS_STUB
    if (m_ctx) { redisFree(m_ctx); m_ctx = nullptr; }
#else
    m_ctx = nullptr;
#endif
}

bool RedisClient::connect() {
#ifdef REDIS_STUB
    // Stub: always "connected" logically but no backend
    return false; // signal no live data -> poller kann fallback verwenden
#else
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
#endif
}

bool RedisClient::authIfNeeded() {
#ifdef REDIS_STUB
    return false;
#else
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
#endif
}

bool RedisClient::ping() {
#ifdef REDIS_STUB
    return false;
#else
    if (!connect()) return false;
    redisReply* reply = (redisReply*)redisCommand(m_ctx, "PING");
    if (!reply) return false;
    bool ok = (reply->type == REDIS_REPLY_STATUS || reply->type == REDIS_REPLY_STRING);
    freeReplyObject(reply);
    return ok;
#endif
}

std::optional<std::string> RedisClient::get(const std::string& key) {
#ifdef REDIS_STUB
    return std::nullopt;
#else
    if (!connect()) return std::nullopt;
    redisReply* reply = (redisReply*)redisCommand(m_ctx, "GET %s", key.c_str());
    if (!reply) return std::nullopt;
    if (reply->type == REDIS_REPLY_NIL) { freeReplyObject(reply); return std::nullopt; }
    if (reply->type != REDIS_REPLY_STRING) { freeReplyObject(reply); return std::nullopt; }
    std::string val(reply->str, reply->len);
    freeReplyObject(reply);
    return val;
#endif
}
