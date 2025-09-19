# QtTrade Frontend - Pure QML Version

Ein modernes Trading-Frontend, das **komplett in Qt Quick/QML** implementiert ist, mit minimaler C++ Abhängigkeit.

## 🚀 Features

### ✨ **Reine QML-Implementierung**
- **Minimaler C++** - Nur `main.cpp` für App-Initialisierung
- **QML-basierte Datenmodelle** - Keine C++ Model-Klassen
- **WebSocket/HTTP Integration** - Direkt in QML
- **Moderne UI-Komponenten** - Vollständig in QML entwickelt

### 📊 **Trading-Features**
- **Market Dashboard** - Live-Marktdaten mit Statistiken
- **Interactive Charts** - Candlestick-Charts mit Timeframes
- **Portfolio Management** - Positionen und P&L-Tracking
- **Order Management** - Order-Historie und Status-Tracking
- **Real-time Notifications** - Push-Benachrichtigungen

### 🎨 **Moderne UI**
- **Dark Theme** - Professionelles Trading-Interface
- **Responsive Design** - Optimiert für verschiedene Bildschirmgrößen
- **Smooth Animations** - Flüssige Übergänge und Effekte
- **Touch-Friendly** - Mobile und Desktop-optimiert

## 🏗️ Architektur

```
QtTradeFrontend_QML/
├── src/
│   └── main_qml.cpp              # Minimaler C++ Entry Point
├── qml/
│   ├── MainQML.qml               # Hauptanwendung
│   ├── Theme.qml                 # Styling System
│   ├── services/
│   │   └── DataService.qml       # WebSocket/HTTP Data Service
│   └── components/
│       ├── Modern*.qml           # Moderne UI-Komponenten
│       ├── *StatCard.qml         # Dashboard-Karten
│       └── *RowDelegate.qml      # Tabellen-Zeilen
├── CMakeLists_QML.txt            # CMake für QML-Version
├── QtTradeFrontend_QML.pro       # qmake für QML-Version
└── qml_pure.qrc                  # QML-Ressourcen
```

## 🛠️ Build & Installation

### Voraussetzungen
- **Qt 5.15+** oder **Qt 6.x**
- **CMake 3.21+** oder **qmake**
- **C++17 Compiler**
- Optional: **Qt WebSockets** für Real-time Data

### Option 1: CMake Build
```bash
# Automatischer Build
./build_qml.sh

# Oder manuell:
mkdir build_qml && cd build_qml
cmake -f ../CMakeLists_QML.txt ..
make -j$(nproc)
```

### Option 2: qmake Build
```bash
qmake QtTradeFrontend_QML.pro
make  # oder mingw32-make / nmake auf Windows
```

### Ausführen
```bash
./QtTradeFrontend_QML
```

## ⚙️ Konfiguration

### WebSocket/HTTP Backend
Die App erwartet einen Backend-Server auf:
- **WebSocket**: `ws://127.0.0.1:7380` (Port+1000)
- **HTTP API**: `http://127.0.0.1:8080/api/`

### Einstellungen
Alle Einstellungen werden automatisch gespeichert:
- **Verbindung**: Redis Host/Port/Password
- **UI**: Theme, Notifications
- **Trading**: Standard-Symbol

## 📡 API Integration

### WebSocket Messages
```json
{
  "channel": "market",
  "payload": {
    "symbol": "AAPL",
    "price": 150.25,
    "change": 2.50,
    "changePercent": 1.69,
    "volume": 1250000
  }
}
```

### HTTP Endpoints
- `GET /api/market` - Marktdaten
- `GET /api/portfolio` - Portfolio-Positionen
- `GET /api/orders` - Order-Historie
- `GET /api/notifications` - Benachrichtigungen

## 🎯 Vorteile der QML-Lösung

### ✅ **Entwicklung**
- **Faster Development** - Live-Reload, kein C++ Rebuild
- **Easier Maintenance** - Ein Technologie-Stack
- **Better Separation** - UI und Logik getrennt
- **Cross-Platform** - Identisches UI überall

### ✅ **Performance**
- **Smaller Binary** - Weniger C++ Code
- **GPU Acceleration** - Qt Quick Scene Graph
- **Smooth Animations** - Hardware-beschleunigt
- **Memory Efficient** - QML Garbage Collection

### ✅ **Features**
- **Modern UI** - Material Design, Animations
- **Touch Support** - Mobile-ready
- **Responsive** - Adaptive Layouts
- **Themeable** - Dynamic Styling

## 🔧 Development

### QML Debugging
```bash
# Debug Build mit QML Debugging
cmake -DCMAKE_BUILD_TYPE=Debug -f ../CMakeLists_QML.txt ..
```

### QML Linting
```bash
# Automatisch im Build-Script
make qml_lint
```

### Live Development
1. Änderungen in QML-Dateien
2. App automatisch neu laden (bei Debug-Builds)
3. Sofortige Vorschau der Änderungen

## 📋 TODO / Roadmap

- [ ] **Trading Integration** - Order-Placement
- [ ] **Advanced Charts** - Technical Indicators
- [ ] **Alerts System** - Price/Volume Alerts
- [ ] **Multi-Account** - Portfolio-Switching
- [ ] **Mobile Version** - Touch-optimized UI
- [ ] **Plugin System** - Custom Indicators

## 🤝 Vergleich: C++ vs QML

| Feature | C++ Version | QML Version |
|---------|-------------|-------------|
| **Development Speed** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **UI Flexibility** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Performance** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Binary Size** | ⭐⭐ | ⭐⭐⭐⭐ |
| **Maintenance** | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Cross-Platform** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

## 📞 Support

Bei Fragen oder Problemen:
1. **QML Debugging** einschalten
2. **Console Output** prüfen
3. **WebSocket/HTTP Connectivity** testen
4. **Qt Version** kompatibilität prüfen

## 📄 License

MIT License - Siehe LICENSE-Datei für Details.

---

**QtTrade Frontend QML** - *Trading made modern with Qt Quick* 🚀