# GitHub Copilot Custom Instructions: Qt Trade – Tradebot Agent Setup (Grok 4)

## Projekt-Übersicht
- **Ziel**: Echtzeit-Aktien-Trading mit ML (AutoGluon) und Alpaca Trade API. Moderne Qt-Frontend (Dark Fusion: tiefschwarz #0a0a0a, Neon-Blau #00ffff Akzente, rahmenlos) für Visualisierung. Backend auf Hetzner (Docker) für Daten/ML/Trading-Logik.
- **Features**: Top 20 US-Ticker (Grok-API), Candlestick-Charts (15-Min), Alpaca-Portfolio, Tradebot für automatische Buy/Sell-Orders, dynamische UI mit pulsierenden Visuals.
- **Training**: AutoGluon täglich (09:00 UTC), retrainiert, wenn Portfolio vs. Prognose >15% abweicht.
- **Sync**: Redis lokal/remote (5-Sekunden-Poll).
- **Sicherheit**: API-Keys in verschlüsselten QSettings (.env).

## Tech-Stack
- **Frontend**: Qt 6.9 (MSVC, 64-bit, Windows), C++17, CMake. Bibliotheken: Qt Charts (QCandlestickSeries), hiredis (Redis), QJsonDocument.
- **Backend**: Python 3.11, Docker Compose v2.28.1, Celery 5.4.0, AutoGluon 1.4.1, redis-py 5.1.0, psycopg2-binary 2.9.9, requests 2.32.3.
- **DB/Cache**: PostgreSQL 15 (TimescaleDB), Redis 7.
- **Broker**: Alpaca API (v2/account/portfolio/history, v2/orders für Trades).
- **Tools**: VSCode, Grok 4 (Agent-Modus), Live Share (lokal Qt + remote Docker).

## Coding-Guidelines
- Modular, Type-Hints (C++/Python), Kommentare (z. B. // API-Token-Validierung). Keine Hardcodes – speichere API-Keys in .env oder QSettings. Tests: Catch2 (C++), pytest (Python).
- **Frontend**: QMainWindow (rahmenlos), QTimer (5s Redis-Poll), QPalette (Dark Fusion).
- **Backend**: Asynchron (Celery), Logging (INFO), Rate-Limits (@retry).

## Frontend-Struktur (Lokal, Windows)
- **Design**: Dark Fusion – #0a0a0a Hintergrund, #00ffff Neon-Akzente, Glow-Effekte (QGraphicsDropShadowEffect). Dynamisch: Sidebar animiert bei Hover (QPropertyAnimation), Charts pulsieren bei Updates (QTimer).
- **Tabs (QStackedWidget)**:
  - **Dashboard**: Top 20 US-Ticker (AAPL, NVDA, MSFT, TSLA, AMZN, META, GOOGL, BRK.B, AVGO, JPM, LLY, V, XOM, PG, UNH, MA, JNJ, COST, HD, BAC) – Grok-API (JSON). QTableView mit Hover-Tooltip (Marktkap/Change).
  - **Charts**: QCandlestickSeries (15-Min OHLCV aus Redis), QLineSeries für Prognosen, Volume-Bar, Hover-Zoom.
  - **Portfolio**: Alpaca-API (/v2/portfolio/history) – Equity-Kurve (QLineSeries), P/L-Balken (grün/rot), Positionen-Liste. Vergleicht mit Prognose: >15% Abweichung trigger Retraining.
  - **Trades**: QTableView für aktive Orders (Kauf/Verkauf, Preis, Status). Zeigt Tradebot-Aktionen („Kauf TSLA um 15:06“).
  - **Einstellungen**: QFormLayout für API-Eingaben:
    - **Backend-API-Token**: Generiert vom Backend, Eingabe via QLineEdit (maskiert), Validierung mit QNetworkAccessManager.
    - **Alpaca Trade API**: Key + Secret (QLineEdit, maskiert), verschlüsselt gespeichert (QSettings).

## Backend-Struktur (Remote, Hetzner Docker)
- **Setup**: Ubuntu 22.04, Docker Compose v2.28.1.
- **Services**:
  - `redis`: Redis 7 (Port 6379), Volume: /app/redis:/data, Passwort: pass123.
  - `postgres`: PostgreSQL 15, DB: qt_trade, Passwort: pass123, Volume: /app/pg:/var/lib/postgresql/data.
  - `worker`: Python 3.11 Image, holt Daten (Finnhub, FMP, Alpaca), trainiert AutoGluon, pusht zu Redis.
  - `traefik`: HTTPS-Router (Port 80/443), Volume: /var/run/docker.sock.
- **Tradebot**: Automatische Trades via Alpaca-API (v2/orders), basierend auf 7-Tage-Prognosen (>5% Gewinn).

## Live Share & Agent-Modus
- **Setup**: Lokal: `code qt-frontend/` (Qt-Code). Remote: `code --remote ssh-root@hetzner-ip /app/qt-trade` (Docker). Live Share: Lokal > „Start Collaboration“, Link kopieren, Remote > „Join Collaboration“.
- **Agent-Prompts**: `@workspace #file ml.md Generiere Charts-Tab mit Tradebot-Logik.` Iteriere: „Fix API-Validierung“ – Grok 4 plant, editiert, fragt nach Bestätigung.
- **Nächste Schritte**: Hochladen > Klon > VSCode öffnen > Live Share starten > `@workspace Baue MVP`.

## Hinweise
- Startet mit Angebotsprojekt (MVP) – sobald du die .md hochlädst, beginnt Grok 4.
- Doxygen: Später integrieren (nach MVP-Fertigstellung).

Grok 4 priorisiert für Echtzeit-Grok-Calls. Fertig in ~45 Min.

---

## 1. Datenpipeline (End-to-End)
```
       +-------------------+        +------------------+        +------------------+
       |  External Feeds   |        |  Raw Storage      |        |  Feature Store    |
       | (Finnhub / FMP /  |  --->  |  (Postgres +     |  --->  | (Derived tables / |
       |  Alpaca / Grok)   |        |   Timescale)     |        |  cached parquet)  |
       +-------------------+        +------------------+        +------------------+
                 |                            |                           |
                 | (batch ingest ETL)         | (feature build jobs)      |
                 v                            v                           v
            +-----------+              +--------------+            +--------------+
            |  Worker   |  <---------> |  AutoGluon    |  ------->  |  Model Store |
            |  (Celery) |   metrics     |  Training     |  models    | (versioned)  |
            +-----------+              +--------------+            +--------------+
                  |                              |                         |
                  | push metrics / forecasts     | register model meta     |
                  v                              v                         |
              +--------- Redis (Serving Layer) ----------------------------+
                  |       |          |                |             |
                  |       |          |                |             |
                  v       v          v                v             v
           market_data  chart_data  predictions   system_status  performance_metrics
                  |                                                  |
                  +------------------ Qt Frontend -------------------+
```

## 2. Feature Engineering
Aktuelle (Baseline) Features pro Symbol & Zeitintervall:
- Preis-Rohwerte: open, high, low, close, volume
- Returns: log_return_1, log_return_3, log_return_6
- Volatilität: rolling_std_6, rolling_std_12
- Momentum: ema_fast (6), ema_slow (24), ema_ratio = ema_fast/ema_slow
- Range / Body: candle_body = close - open, high_low_range = high - low
- Normalisierte Volumen-Anomalie: volume / rolling_volume_mean_20

Geplant:
- Market Breadth / sektorale Indikatoren (Anteil steigender Symbole)
- Externe Sentiment-Scores (Grok / News) -> sentiment_score_normalized
- Volatility Crush / Earnings Flags

## 3. Trainings-Workflow
1. Scheduler (Celery Beat / Cron) löst täglich 09:00 UTC initialen Training-Task aus.
2. Data Snapshot (letzte N Tage, N=90 default) wird geladen (TimescaleDB).
3. Feature Pipeline (Python Modul `features/compute.py`) generiert DataFrame.
4. AutoGluon TabularPredictor Fit (regression, Ziel: next_close oder horizon_k = 3 * Intervall).
5. Auswahl Top-Model nach `validation_score` (RMSE oder MAPE) -> Persistenz `model_store/model_<timestamp>/`.
6. Registrierung Meta Info in Redis Key: `ml_status` / ggf. `model_meta_current`.
7. Ableitung Forecast Points für definierte Ausgabahorizonte -> Schreiben nach `predictions_<SYMBOL>` (kompakt Schema v1.1).

### Retrain Conditions (zusätzlich zum täglichen Slot)
- Drift: MAPE rolling(24h) > 1.25 * validation_mape
- Performance Delta: Portfolio Equity vs. modellierte Equity > 15%
- Force Flag: `manual_trigger_ml == true`

## 4. Evaluierung & Metriken
Speicherung in Redis / Postgres:
- `performance_metrics.api_response_times.*` (Latenzen externer Feeds)
- `performance_metrics.data_freshness.*`
- Trainingsmetriken (Persistenz in Postgres Tabelle `ml_training_runs`):
  - run_id, started_at, duration_sec, algo_mix, validation_metric, best_model_name
  - feature_count, row_count, horizon, symbol_universe_size
- Live Drift Monitoring: Key `ml_drift` (geplant) mit Feldern:
  - symbol -> { mape_live, mape_val, drift_ratio }

## 5. Model Versionierung
Template Verzeichnisstruktur:
```
model_store/
  model_2025-09-13_09-00-02/
    predictor.pkl
    featureset.json
    training_meta.json
    leaderboard.csv
    README.md
  latest -> symlink auf aktuell bestes Modell
```

`training_meta.json` Beispiel:
```json
{
  "run_id": "2025-09-13T09:00:02Z",
  "symbols": ["AAPL","NVDA","MSFT"],
  "rows": 5400,
  "features": 42,
  "horizon": 3,
  "validation_metric": "MAPE",
  "validation_score": 0.0213,
  "best_model": "WeightedEnsemble_L2",
  "schema_version": "1.1"
}
```

## 6. Redis Key Mapping (ML Relevanz, Schema 1.1)
| Key | Zweck | Format Kurz |
|-----|-------|------------|
| `chart_data_<SYMBOL>` | Candles kompakt | [{"t","o","h","l","c"(,"vol")}] |
| `predictions_<SYMBOL>` | Forecast Punkte | [{"t","v"}] |
| `ml_status` | Laufzeitstatus | { training_active, last_training, training_progress, model_accuracy, next_scheduled } |
| `ml_training_log` | Historie Trainingsereignisse | [{ timestamp, event, details }] |
| `manual_trigger_ml` | Boolean Trigger | "true"/"false" |
| `performance_metrics` | Systemmetriken | siehe README |
| `schema_meta` | Versionierung | { version, compat, legacy_mapping }

## 7. Security / Secrets
- Produktions-API Keys niemals im Repo (`.gitignore` abgedeckt: `.env`).
- Empfehlung: Hashicorp Vault oder AWS SSM Parameter Store für langfristig.
- Lokal: `.env` + ENV Variablen Injection in Docker Compose.
- Frontend: Keine persistente Speicherung von Secrets außer optional verschlüsselt via QSettings (später).

## 8. Minimaler AutoGluon Trainings-Snippet (Pseudo-Code)
```python
from autogluon.tabular import TabularDataset, TabularPredictor
from pathlib import Path
import pandas as pd, json, time

def load_data(conn, symbols, days=90):
    # SQL Query (TimescaleDB) -> DataFrame mit Spalten: ts, symbol, open, high, low, close, volume
    ...

def build_features(df):
    df = df.sort_values(['symbol','ts'])
    df['log_return_1'] = (df.groupby('symbol').close.pct_change()+1).apply(lambda x: 0 if pd.isna(x) else x).pipe(lambda s: s.clip(-0.5,0.5))
    # Weitere Features (EMA, Vol, etc.)
    return df

def train(df):
    target_horizon = 3  # z.B. 3 * 15min -> 45min ahead
    # Zukunftswert als Ziel verschieben
    df['target'] = df.groupby('symbol').close.shift(-target_horizon)
    train_df = df.dropna(subset=['target'])
    predictor = TabularPredictor(label='target', path='model_store/temp').fit(train_df)
    return predictor

if __name__ == '__main__':
    raw = load_data(...)
    feats = build_features(raw)
    predictor = train(feats)
    # Forecast generieren
    # Für jedes symbol: letzte Zeile -> predict -> Redis schreiben (predictions_<SYMBOL>)
```

## 9. Deployment Strategie (ML Teil)
- Build separater Worker Container Image (Dockerfile.worker) mit gepinntem AutoGluon.
- Rolling Redeploy nach erfolgreichem Training nur falls validation_score <= threshold.
- Canary Möglichkeit: Neuer Predictor paralleles Schreiben nach `predictions_candidate_<SYMBOL>` -> Vergleich -> Promotion.

## 10. Monitoring & Drift
- Geplant: Key `ml_drift` + Grafana Dashboard (Prometheus Export via Sidecar).
- Metriken: rolling_mape, forecast_bias, coverage (falls später Intervall-Prognosen).
- Alert Schwellen: drift_ratio > 1.4 (Warnung), >1.8 (Retrain sofort + Notify).

## 11. Roadmap (ML spezifisch)
| Phase | Inhalt |
|-------|--------|
| 0 | Basis: Kompakte Schema Keys, einfache Regression (aktueller Stand) |
| 1 | Feature-Erweiterung (Momentum, Sentiment), Confidence `conf` Feld |
| 2 | Ensemble / Multi-Horizon Output, Candidate Promotion Flow |
| 3 | Drift Dashboard + Canary Deploys |
| 4 | Risk-Modul (VaR/Expected Shortfall) Integration |
| 5 | Reinforcement / Policy Layer für Order-Auswahl |

## 12. Offene Punkte / To Decide
- Einheitliche Zeitauflösung (Sekunden vs. ISO8601) – aktuell Candles: Epoch / t als String; Empfehlung: numerisch als int.
- Volume Konsistenz (optional) – Standardisieren: Wenn fehlt -> omit statt 0.
- Confidence Werte (0..1) – Optionaler Key `conf` in `predictions_<SYMBOL>`.

## 13. Empfohlene Verbesserungen (Kurzfristig)
1. Implementiere Fallback Parser für Legacy Candle Keys im Frontend.
2. Candidate Predictions Flow vorbereiten (`predictions_candidate_<SYMBOL>` + Vergleich).
3. Drift Key Schema definieren (`ml_drift`).
4. CI: Linter + schneller Smoke-Test (Import AutoGluon + Version print).
5. Tag v0.1.0 + Changelog.

---
Letztes Update: 2025-09-13 – Ziehe `schema_meta.version` bei strukturellen Änderungen hoch.
