#include <iostream>
#include <cstdlib>
#include "redisclient.h"

int main() {
    const char* hostEnv = std::getenv("REDIS_HOST");
    const char* portEnv = std::getenv("REDIS_PORT");
    std::string host = hostEnv ? hostEnv : "127.0.0.1";
    int port = portEnv ? std::atoi(portEnv) : 6380;
    RedisClient client(host, port, 0, "");
    if(!client.connect()) {
        std::cerr << "Connect failed to " << host << ":" << port << "\n";
        return 1;
    }
    bool ok = client.ping();
    std::cout << (ok?"PING ok":"PING failed") << " for " << host << ":" << port << "\n";
    return ok?0:2;
}
