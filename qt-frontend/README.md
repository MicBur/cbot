# Qt Trade Frontend - Local Setup

## Installation (auf deinem lokalen Computer)

### Windows:
1. Lade Qt Online Installer von https://www.qt.io/download herunter
2. Installiere Qt 6.9 mit folgenden Komponenten:
   - Qt Charts
   - CMake Support
   - MinGW oder MSVC Compiler

### Linux (Ubuntu/Debian):
```bash
sudo apt update
sudo apt install qt6-base-dev qt6-charts-dev cmake build-essential redis-tools
```

### macOS:
```bash
brew install qt@6 cmake redis
export PATH="/opt/homebrew/opt/qt@6/bin:$PATH"
```

## Projekt kompilieren:

```bash
# 1. Klone/kopiere das qt-frontend Verzeichnis lokal
# 2. Erstelle Build-Verzeichnis
cd qt-frontend
mkdir build && cd build

# 3. Konfiguriere mit CMake
cmake .. -DCMAKE_PREFIX_PATH=/path/to/qt6

# 4. Kompiliere
make -j4    # Linux/Mac
# oder
cmake --build . --config Release  # Windows
```

## Remote-Verbindung einrichten:

### 1. SSH-Tunnel für Redis (sicher):
```bash
ssh -L 6379:localhost:6379 user@YOUR_REMOTE_SERVER_IP
```

### 2. Direkte Verbindung (wenn Firewall offen):
Ändere in main.cpp:
```cpp
// Verbinde zu Remote-Redis
RedisClient *redis = new RedisClient("YOUR_REMOTE_SERVER_IP", 6379, "pass123");
```

### 3. VPN-Verbindung (empfohlen für Produktion):
```bash
# Verwende WireGuard oder OpenVPN zur sicheren Verbindung
```

## Starten der Anwendung:

```bash
cd build
./QtTrade    # Linux/Mac
# oder
QtTrade.exe  # Windows
```

## Features die du sehen wirst:

1. **Dashboard-Tab**: Live-Ticker-Daten (alle 5 Sekunden aktualisiert)
2. **Charts-Tab**: Candlestick-Charts mit ML-Prognosen
3. **Portfolio-Tab**: Equity-Kurve vom Alpaca-Account
4. **Trades-Tab**: Aktive Orders und Tradebot-Aktionen
5. **Settings-Tab**: API-Keys eingeben und Model-Status

## Troubleshooting:

- **Keine Verbindung zu Redis**: Prüfe Firewall und Port 6379
- **Qt nicht gefunden**: Setze CMAKE_PREFIX_PATH auf Qt-Installation
- **Kompilier-Fehler**: Installiere alle Qt6-Entwickler-Pakete

## Live-Daten testen:
```bash
# Teste Redis-Verbindung von lokal:
redis-cli -h YOUR_REMOTE_SERVER_IP -p 6379 -a pass123 get market_data
```