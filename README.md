# Qt Trade Bot - AI-Powered Trading Platform

## Backend Architecture

### Core Components

**Worker System (worker.py)**
- Celery-based task queue for automated trading operations
- Redis for real-time data caching and message brokering
- PostgreSQL for persistent data storage
- AutoGluon ML for price predictions
- Grok AI integration for market analysis
- Alpaca API for live trading execution

### Key Features

#### 🤖 Machine Learning
- **AutoGluon Integration**: Automated ML model training for price predictions
- **Real-time Predictions**: 15-minute interval forecasting for 7-day windows
- **Feature Engineering**: OHLCV data, volatility, price changes, time-based features
- **Model Persistence**: Trained models stored and versioned

#### 🧠 AI Market Analysis
- **Grok AI Integration**: Daily top-10 stock recommendations
- **Deeper Search**: Comprehensive market analysis with real-time data
- **Sentiment Analysis**: AI-powered market sentiment evaluation
- **Risk Assessment**: Automated risk scoring for trading decisions

#### 📊 Data Pipeline
- **Multi-Source Data**: Finnhub, FMP, Alpaca APIs
- **Real-time Streaming**: 15-minute OHLCV candles
- **Historical Data**: 30-day lookback for ML training
- **Portfolio Sync**: Live portfolio and position tracking

#### 💼 Trading Engine
- **Automated Trading**: ML-driven buy/sell decisions
- **Risk Management**: Position sizing and stop-loss integration
- **Paper Trading**: Safe testing environment
- **Live Trading**: Production-ready execution via Alpaca

### Installation & Setup (Docker)

#### Prerequisites
```bash
# Docker and Docker Compose
sudo apt install docker.io docker-compose

# Git (for cloning)
sudo apt install git
```

#### Environment Setup
```bash
# Create environment file
cp .env.example .env

# Edit .env and add your API keys
# FINNHUB_API_KEY=...
# ALPACA_API_KEY=...
# ALPACA_SECRET=...
# XAI_API_KEY=...
```

#### Docker Deployment
```bash
# Build and start services (Redis, Postgres, worker, beat)
docker compose up -d --build

# View logs
docker compose logs -f worker

# Stop services
docker compose down
```

#### Notes
- Redis image updated to 7.x, Postgres to 15.x (alpine). Volumes `pgdata` and `redisdata` persist data.
- Celery beat runs as a separate service `beat` for scheduled tasks.

### Local Development (optional)
- Python 3.11 with requirements in `requirements.txt`.
- Start worker locally: `export REDIS_URL=... DATABASE_URL=... && celery -A worker worker -l info`.

### API Endpoints & Data Format

All data is stored in Redis using JSON format for Qt frontend compatibility:

#### Market Data
```json
{
  "market_data": {
    "AAPL": {"price": 234.07, "change": 4.04, "change_percent": 1.76},
    "NVDA": {"price": 177.82, "change": 0.65, "change_percent": 0.37}
  }
}
```

#### Portfolio Data
```json
{
  "portfolio_positions": [
    {"ticker": "AAPL", "qty": "100", "avg_price": "150.25", "side": "long"}
  ],
  "portfolio_equity": [
    {"timestamp": "2025-09-14T08:38:56", "equity_value": "110113.42"}
  ]
}
```

#### AI Recommendations
```json
{
  "grok_top10": [
    {"ticker": "NVDA", "score": 0.88, "reason": "Strong AI momentum"},
    {"ticker": "TSLA", "score": 0.85, "reason": "Product announcements"}
  ]
}
```

### Automated Scheduling

**Celery Beat Schedule:** (see `docker-compose.yml`)
- **Data Fetching**: Every 10 minutes
- **Portfolio Sync**: Every 5 minutes  
- **ML Training**: Daily at 09:00 UTC
- **Grok Analysis**: Daily at 09:05 UTC
- **Auto Trading**: Every 10 minutes

### Manual Triggers

Frontend can manually trigger:
```bash
# Manual ML training
redis-cli -a pass123 SET manual_trigger_ml "true"

# Manual Grok analysis
redis-cli -a pass123 SET manual_trigger_grok "true"
```

### Database Schema

**Core Tables:**
- `market_data`: OHLCV candles with 15-min intervals
- `portfolio_positions`: Current positions and equity
- `grok_recommendations`: AI-generated stock picks
- `ml_predictions`: Model forecasts and accuracy metrics

### Monitoring & Logging

**System Status:**
```bash
# Check all containers
docker-compose ps

# View worker logs
docker logs qbot-worker-1

# Redis monitoring
redis-cli -a pass123 monitor
```

**Health Checks:**
- API connectivity status
- Data freshness indicators
- Model performance metrics
- Trading execution logs

### Security

- API keys via `.env` only (never hardcode keys in source)
- Redis password protection
- PostgreSQL authentication
- SSL/TLS for external API calls

### Qt Frontend Integration

The backend provides JSON-formatted data via Redis for seamless Qt C++ integration:

```cpp
// Qt Redis client example
RedisClient *redis = new RedisClient("server-ip", 6379, "pass123");
QJsonObject marketData = redis->getMarketData();
double applePrice = marketData["AAPL"]["price"].toDouble();
```

### Performance

- **Data Processing**: 2000+ market data points per training cycle
- **ML Training**: 5-minute AutoGluon model updates
- **API Response**: <500ms average for all endpoints
- **Memory Usage**: ~512MB typical worker footprint

### Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### Support

For questions or issues:
- Open a GitHub issue
- Check the documentation in `redis.txt` and `ml.md`
- Review Docker logs with `docker compose logs -f worker`

---

**Technologies Used:**
- Python 3.11 + Celery
- Redis + PostgreSQL
- AutoGluon ML
- Docker + Docker Compose
- Alpaca Trading API
- Grok AI (xAI)
- Qt 6 C++ Frontend