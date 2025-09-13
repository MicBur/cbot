# Qt Trade Frontend (C++ / Qt Quick)

Dark Neon Trading / ML Frontend (reines C++ + Qt Quick) das mehrere Redis Keys (Port 6380) pollt und dynamisch animierte UI Komponenten bereitstellt.

> Schema Version: Derzeit Redis Schema v1.1 (kompakte Candles `o,h,l,c,t` & Forecast Punkte `t,v`). Siehe Abschnitt "Redis Schema & Versionierung".

## Aktueller Funktionsumfang
| Kategorie | Feature |
|-----------|---------|
| Daten | Redis Poll (5s) für `market_data`, `portfolio_positions`, `active_orders`, `system_status`, `notifications` |
| Modelle | `MarketModel` (diff updates), `PortfolioModel`, `OrdersModel`, `StatusModel`, `NotificationsModel` |
| UI | Dark Theme (`Theme.qml`), Seiten-Navigation (Dashboard, Charts, Portfolio, Orders, Settings), klickbare Symbolauswahl in MarketList |
| Charts | Canvas-basierter `CandleChart` (echte Redis-Bindung für `chart_data_<SYMBOL>` & `predictions_<SYMBOL>` falls vorhanden, sonst Fallback Mock) mit Forecast-Dotted-Line |
| Notifications | Slide-In Drawer mit Mark-as-Read und Typ-Farbkodierung |
| Status | Mehrere Status Badges (Redis, Postgres, Worker, Alpaca, Grok) mit Pulse bei Zustandswechsel |
| Fehlerhandling | Overlay bei Redis Disconnect |
| Animationen (Phase 1) | Preis Flash + Smooth Count-Up, Neon Pulse für aktive Tabs, Status-Badge Pulse, Sparkline Mini-Chart + Farbverlauf |

## Quick Start (TL;DR)
```powershell
# Qt Pfad setzen
$env:CMAKE_PREFIX_PATH="C:/Qt/6.6.0/msvc2019_64"
mkdir build; cd build
cmake -G "Ninja" -DCMAKE_BUILD_TYPE=Release ..
cmake --build . --target QtTradeFrontend
./QtTradeFrontend.exe --redis-host 127.0.0.1 --redis-port 6380
```
Optional Deployment (Qt DLLs): windeployqt QtTradeFrontend.exe

## Deployment & Packaging (Windows)
Für eine distributable Version (inkl. aller benötigten Qt/QML Module und `hiredis.dll`) kannst du entweder das PowerShell Skript nutzen oder die Schritte manuell ausführen.

### 1. Automatisiertes Deployment (empfohlen)
Skript: `scripts/deploy.ps1`

Parameter Übersicht:
| Parameter | Default | Beschreibung |
|-----------|---------|--------------|
| `-Configuration` | Release | Build-Konfiguration (Debug/Release) |
| `-QtRoot` | (aus CMAKE_PREFIX_PATH | versucht autodetect) | Qt Basispfad (enthält `bin`, `qml`) |
| `-DistDir` | dist | Zielordner für entpackte Runtime |
| `-Zip` | false | Erstellt zusätzlich ein Zip-Archiv `QtTradeFrontend-<Version>.zip` |
| `-PruneMinimal` | false | Entfernt optionale/ große nicht benötigte Module (WebEngine, Beispiele, Designer, unnötige Translations) |

Beispiel:
```powershell
pwsh -ExecutionPolicy Bypass -File .\scripts\deploy.ps1 -Configuration Release -QtRoot "C:\Qt\6.6.0\msvc2019_64" -DistDir dist -Zip -PruneMinimal
```
Ergebnis:
```
dist/                 # Laufzeitordner
  QtTradeFrontend.exe
  hiredis.dll
  platforms/qwindows.dll
  qml/...
QtTradeFrontend-0.1.0.zip  # (falls -Zip)
```

### 2. Manuelles Deployment (Fallback)
Im Build-Verzeichnis:
```powershell
# ggf. vorher: cmake --build . --target QtTradeFrontend --config Release
& "C:/Qt/6.6.0/msvc2019_64/bin/windeployqt.exe" .\QtTradeFrontend.exe
Copy-Item ..\hiredis-1.3.0\dll\hiredis.dll . -Force  # Pfad anpassen falls anders
```
Falls QML Effekte wie `DropShadow` fehlen: Stelle sicher, dass nach Änderung der QML Importe (z.B. `import Qt5Compat.GraphicalEffects`) windeployqt erneut ausgeführt wurde.

### 3. Optionaler Minimal-Prune (manuell)
Nicht benötigte Verzeichnisse können nach dem Deployment entfernt werden (nur wenn deine App sie nicht nutzt):
```
dist\qml\QtWeb*          # WebEngine / WebView Module
dist\qml\QtCharts*       # falls nicht benutzt
dist\translations\qt_*.qm (außer qt_de/qt_en falls benötigt)
dist\resources\* (Designer/Examples)
```
Skript-Variante erledigt dies bei `-PruneMinimal` automatisch (konservativ, lässt Kernmodule intakt).

### 4. Versionierung
Die Version stammt aus `project(VERSION ...)` (derzeit 0.1.0) und wird in `version.h` generiert (`QTTRADE_VERSION`). Für künftige Releases einfach in `CMakeLists.txt` anpassen und erneut bauen + deployen.

### 5. Starten aus dist
```powershell
cd dist
./QtTradeFrontend.exe --redis-host 127.0.0.1 --redis-port 6380
```

### 6. Geplante Verbesserung
Ein automatischer Post-Build Copy-Schritt für `hiredis.dll` kann in CMake ergänzt werden (siehe unten in Abschnitt "Optionale CMake Ergänzung").

### Troubleshooting
| Symptom | Ursache | Lösung |
|---------|---------|--------|
| "Failed to load platform plugin 'windows'" | `platforms/qwindows.dll` fehlt | Erneut windeployqt ausführen / prüfen ob `dist/platforms` existiert |
| QML Fehler: `DropShadow ist kein Typ` | GraphicalEffects Modul nicht paketiert | `import Qt5Compat.GraphicalEffects` in QML + erneut windeployqt |
| Sofortiger Exit ohne Fenster | Fehlende DLL oder QML Parse Fehler | Start mit `set QT_DEBUG_PLUGINS=1` / `set QML_IMPORT_TRACE=1` prüfen |
| Redis Status bleibt rot | Falscher Host/Port oder Redis nicht erreichbar | Parameter / Env Variablen prüfen (`--redis-host`, Firewall) |
| Hohe Verzögerung / seltene Updates | Backoff aktiv nach Fehlern | Logs prüfen; Verbindung stabil -> Backoff normalisiert sich automatisch |

Debug Env Variablen (vor Start setzen):
```powershell
$env:QT_DEBUG_PLUGINS=1
$env:QML_IMPORT_TRACE=1
./QtTradeFrontend.exe
```

### Optionale CMake Ergänzung (hiredis DLL Copy)
Falls `hiredis.dll` nicht automatisch im Build-Ausgabeverzeichnis landet:
```cmake
add_custom_command(TARGET QtTradeFrontend POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
          $<TARGET_FILE:hiredis>
          $<TARGET_FILE_DIR:QtTradeFrontend>)
```
Damit landet `hiredis.dll` direkt neben der Exe und wird beim Deployment mitgenommen.

---

## Release Workflow (Empfohlen)
1. Versionsnummer in `CMakeLists.txt` erhöhen
2. Bauen (Release)
3. Deployment Skript ausführen mit `-Zip -PruneMinimal`
4. Teststart aus `dist`
5. Git Tag setzen: `git tag v<Version>; git push --tags`
6. GitHub Release anlegen (Zip anhängen, Changelog Auszug)

Changelog-Abschnitt für 0.1.0 (Kurzform):
```
Initiale Version: Core UI, Redis Polling, Diff Models, Market/Portfolio/Orders/Status/Notifications, Candle + Forecast Chart, Deployment Skript.
```

## Noch offene / geplante Erweiterungen
- Erweiterte Chart Overlays (Volumen, VWAP, Indikatoren)
- Confidence Bands / Error Channels für Forecast
- Shader / Glow Effekte (Bloom / Noise Overlay)
- Erweiterte Drawer Animation (Elastic / Spring)
- Persistente User Settings (Layout / Theme Variationen, letztes Symbol)
- Tooltip Metriken (Latenz, letzter Heartbeat) über StatusBadges
- Fallback Parser für Legacy Candle Felder (timestamp/open/high/low/close/volume)
- CI Workflow (GitHub Actions) für Build + Minimal Smoke Test
- Tagging & Release Pipeline (v0.1.0)
  - (Basis umgesetzt: Version, Deployment Script, Packaging Anleitung)

## Voraussetzungen
- Qt 6.6+ (Core, Quick, ggf. Quick Controls, Charts optional später)
- CMake >= 3.21
- MSVC (oder MinGW) – Beispiel hier: Windows + MSVC
- hiredis (Library + Header) installiert / im Pfad

## Build Schritte (Windows PowerShell)
```powershell
# Pfade anpassen
$env:CMAKE_PREFIX_PATH="C:/Qt/6.6.0/msvc2019_64"  # oder deine Qt Version

# Out-of-source Build
mkdir build; cd build
cmake -G "Ninja" -DCMAKE_BUILD_TYPE=Release -DQT_QML_GENERATE_QMLLS_INI=ON ..
cmake --build . --target QtTradeFrontend

# Optional Deployment (stellt Qt DLLs bereit)
& "$env:CMAKE_PREFIX_PATH/bin/windeployqt.exe" .\QtTradeFrontend.exe
```

Falls du kein Ninja hast, kannst du `-G "Visual Studio 17 2022"` verwenden.

### Alternative: qmake Build (zusätzlich zur CMake Variante)
Voraussetzung: Qt Entwicklungs-Eingabeaufforderung oder env: `qmake` im PATH.

#### MinGW Beispiel
```powershell
qmake QtTradeFrontend.pro
mingw32-make -j4
./QtTradeFrontend.exe
```

#### MSVC Beispiel (Developer Command Prompt)
```powershell
qmake QtTradeFrontend.pro
nmake
QtTradeFrontend.exe
```

Deployment (Qt libs):
```powershell
windeployqt QtTradeFrontend.exe
```

## Ausführen
```powershell
# Im build Verzeichnis
./QtTradeFrontend.exe
```

## CLI & Environment Variablen
Bereits implementiert in `main.cpp` mittels `QCommandLineParser` + Fallback auf Environment:

CLI Optionen:
```
--redis-host / -r   (Default 127.0.0.1)
--redis-port / -p   (Default 6380)
--redis-password / -w (Default "")
--perf-log / -L     (Optional: Poll Latenz Logging)
```

Environment (überschreibt CLI Defaults, falls gesetzt):
```
REDIS_HOST
REDIS_PORT
REDIS_PASSWORD
PERF_LOG ("1" aktiviert Performance Logging)
```

Beispiel:
```powershell
$env:REDIS_HOST="10.0.0.12"; $env:REDIS_PORT="6380"; ./QtTradeFrontend.exe -r 127.0.0.1
```
Resultat: Host = 10.0.0.12 (ENV gewinnt).

## Verwendete Redis Keys
| Key | Typ | Beschreibung |
|-----|-----|--------------|
| `market_data` | JSON Objekt | Symbol -> { price, change, change_percent } |
| `portfolio_positions` | JSON Array | [{ ticker, qty, avg_price, side }, ...] |
| `active_orders` | JSON Array | [{ ticker, side, price, status, timestamp }, ...] |
| `system_status` | JSON Objekt | Flags: redis_connected, postgres_connected, worker_running, alpaca_api_active, grok_api_active, last_heartbeat |
| `notifications` | JSON Array | [{ title, message, type, timestamp, read }, ...] |
| `chart_data_<TICKER>` | JSON Array | Candle Daten (o,h,l,c,t) |
| `predictions_<TICKER>` | JSON Array | Forecast Punkte { t, v } |

## Redis Schema & Versionierung
Aktuelle Schema-Version: **1.1** (festgehalten in `schema_meta` Key – siehe `redis.txt`).

Änderungen v1.1:
- Candles: Verbose Felder (`timestamp/open/high/low/close/volume`) -> kompakt (`t/o/h/l/c` + optional `vol`).
- Predictions: Verbose (`timestamp/predicted_price`) -> kompakt (`t/v`).

`schema_meta` Beispiel:
```json
{
  "version": "1.1",
  "compat": {
    "candles_required": ["o","h","l","c","t"],
    "candles_optional": ["vol"],
    "predictions_required": ["t","v"],
    "legacy_mapping": {
      "timestamp":"t", "open":"o", "high":"h", "low":"l", "close":"c", "predicted_price":"v", "volume":"vol"
    }
  }
}
```

Migrationsstrategie Backend (Empfohlen):
1. Parallel legacy Keys für 1 Deploy-Zyklus mitschreiben (z.B. `chart_data_raw_<SYMBOL>`).
2. Frontend nur neue kompakten Keys lesen.
3. Nach Verifikation Legacy Keys entfernen.

## Architektur Übersicht
Schichtenmodell (vereinfacht):
```
Redis -> RedisClient (C++) -> DataPoller (Timer + Dispatch) -> Modelle (QAbstractListModel) -> QML Views/Components
```
Kernkomponenten:
- `RedisClient`: Minimal Wrapper (connect, get/ping)
- `DataPoller`: Periodischer Abruf (Intervall + Exponential Backoff), verteilt JSON an Models
- Models: `MarketModel`, `PortfolioModel`, `OrdersModel`, `StatusModel`, `NotificationsModel`, `ChartDataModel`, `PredictionsModel`
- QML UI: MarketList, CandleChart, StatusBadges, Notifications Drawer, SideNav

## Datenfluss (Polling -> UI)
```
Timer tick -> DataPoller::poll()
  -> GET market_data -> MarketModel::updateFromJson() (diff)
  -> GET portfolio_positions -> PortfolioModel
  -> GET active_orders -> OrdersModel
  -> GET system_status -> StatusModel
  -> GET notifications -> NotificationsModel
  -> (wenn currentSymbol gesetzt)
       -> GET chart_data_<SYMBOL> -> ChartDataModel::updateFromJson()
       -> GET predictions_<SYMBOL> -> PredictionsModel::updateFromJson()
Signals -> QML Bindings -> UI aktualisiert animiert
```

Backoff Strategie:
```
Start Intervall: 5s
Fehler n -> 5s,10s,20s,30s (Cap)
Erfolg -> Reset auf 5s
```

## Model Rollen (Roles)
| Model | Rollen | Beschreibung |
|-------|--------|--------------|
| MarketModel | symbol, price, change, changePercent, direction | direction: -1/0/1 für Preisrichtung Flash |
| ChartDataModel | o, h, l, c, t | kompaktes Candle Schema |
| PredictionsModel | t, v | Forecast Punkte |
| NotificationsModel | id, type, title, message, timestamp, read | Drawer Darstellung |

## Performance Aspekte
- Diff Updates im `MarketModel` minimieren QML Rebuilds
- ResetModel nur für Candle/Forecast gewollt (komplette Erneuerung bei Symbolwechsel)
- Minimale JSON Parsing-Pfade (direkt QJsonArray -> interne Strukturen)
- Optionales Performance Logging (`--perf-log`) für Latenzbeobachtung

## Erweiterbarkeit
- Orderbuch / Depth könnten als eigenes Model analog angefügt werden
- Indicators (EMA, RSI) precompute im Backend -> separater Key (`indicators_<SYMBOL>`) denkbar
- Multi-Source Aggregation (mehrere Redis Namespaces) via konfigurierter Prefix-Liste

## Build Matrix (zukünftig CI Empfehlung)
| OS | Compiler | Status |
|----|----------|--------|
| Windows | MSVC / Ninja | Ziel (Release + windeployqt) |
| Linux | GCC / Clang | Smoke Build |
| macOS | Clang | Optional |

Geplanter CI Job: Configure + Build + (Headless) Instanziierung von QGuiApplication für Smoke Test.

## Projektstruktur (gekürzt)
```
CMakeLists.txt
src/
  main.cpp
  redisclient.*          # hiredis Wrapper
  marketmodel.*          # Diff Update List Model
  portfoliomodel.*
  ordersmodel.*
  statusmodel.*
  notificationsmodel.*
  datapoller.*           # Polling & Dispatch
qml/
  Main.qml               # App Layout + Drawer + Pages
  Theme.qml              # Farben & Timings
  components/
    MarketList.qml
    SideNav.qml
    StatusBadge.qml
    CandleChart.qml
```

## Technische Highlights
- Diff-basierte Updates im `MarketModel` vermeiden ListView-Flackern
- Pulse/Flash Animationen über gezielte Signals (`rowAnimated`) und State Transitions
- Canvas Rendering für Chart (unabhängig von QtCharts) -> leichtgewichtig + volle Kontrolle
- Erweiterbares Key-Mapping im `DataPoller`

## Notification Drawer
Aufruf über schwebenden 🔔 Button rechts unten. Mark-As-Read durch Click auf Eintrag (delegiert an `notificationsModel.markRead(index)`).

## Status Badges
Farb- & Pulse-Feedback bei Zustandswechsel; Basiert auf `StatusModel` Properties. Geplante Erweiterung: Tooltip mit letzter Heartbeat-Zeit & Latenz.

## Health & Performance
- Letzte Poll Latenz und Timestamp via `poller.lastLatencyMs` / `poller.lastPollTime`
- Exponentieller Backoff (5s -> 10s -> 20s -> 30s) bei Disconnect, Reset bei Erfolg
- Optionales Logging aktivierbar über `--perf-log` oder `PERF_LOG=1`

## CandleChart Placeholder
Mock Candle/Forecast Daten generiert lokal solange keine echten Keys vorliegen. Austauschbar durch Binding auf zukünftige Redis Keys.

## Animationen (Phase 1)
Implemented: Preis Flash, Smooth Count-Up (NumberAnimation), Neon Tab Pulse, Status Badge Pulse.
Geplant (Phase 2): Sparkline Fade Sweep, Drawer Elastic Transition, Shader Bloom.

## Nächste sinnvolle Schritte
1. Erweiterte Chart Overlays (Volumen / Indikatoren)
2. Confidence Bands für Forecast
3. Persistenter User State (Tab & Symbol Speicherung)
4. Shader / Bloom Pipeline Prototyp
5. Tooltips & erweiterte Status Telemetrie
## Symbolauswahl & Sofort-Update
Ein Klick auf ein Symbol in der MarketList markiert die Zeile (Highlight + Border), setzt `poller.currentSymbol` und löst über `poller.triggerNow()` sofort einen zusätzlichen Poll aus. Dadurch werden Candle- und Forecast-Daten ohne Wartezeit auf das normale Intervall aktualisiert. Der `CandleChart` reagiert automatisch über die gebundenen Modelle.


## Lizenz
MIT (Placeholder – anpassen falls benötigt)

---
Fragen / nächste Schritte: Einfach melden – z.B. wenn Chart-Daten real angebunden oder weitere Animationen priorisiert werden sollen.
