# Qt Trade Frontend - Deployment Guide

## Overview

This guide explains how to deploy the Qt Trade Frontend with the enhanced ML-powered trading bot, Grok AI analysis, and 7-day predictions.

## Architecture

```
┌─────────────────────────┐     ┌──────────────────────────┐
│   Local Machine         │     │   Remote Server          │
│                         │     │   (Docker Host)          │
│  ┌─────────────────┐   │     │                          │
│  │ Qt Frontend     │   │     │  ┌────────────────────┐  │
│  │ (Windows/Linux) │◄──┼─────┼──┤ Redis              │  │
│  └─────────────────┘   │     │  │ Port: 6380         │  │
│                         │     │  └────────────────────┘  │
│                         │     │           ▲              │
│                         │     │           │              │
│                         │     │  ┌────────┴───────────┐  │
│                         │     │  │ ML Worker          │  │
│                         │     │  │ - 7-day predictions│  │
│                         │     │  │ - 5-min intervals  │  │
│                         │     │  └────────────────────┘  │
│                         │     │           ▲              │
│                         │     │           │              │
│                         │     │  ┌────────┴───────────┐  │
│                         │     │  │ Trading Bot        │  │
│                         │     │  │ - Auto buy/sell    │  │
│                         │     │  │ - 7-day max hold   │  │
│                         │     │  └────────────────────┘  │
│                         │     │           ▲              │
│                         │     │           │              │
│                         │     │  ┌────────┴───────────┐  │
│                         │     │  │ Grok Analyzer      │  │
│                         │     │  │ - Deep search      │  │
│                         │     │  │ - AI analysis      │  │
│                         │     │  └────────────────────┘  │
└─────────────────────────┘     └──────────────────────────┘
```

## Remote Server Setup

### 1. Prerequisites

- Ubuntu 22.04 or later
- Docker Engine 24.0+
- Docker Compose v2.28.1+
- Open ports: 80, 443, 6380, 5433

### 2. Clone Repository

```bash
git clone https://github.com/your-repo/qt-trade-frontend.git
cd qt-trade-frontend
```

### 3. Configure Environment

Create `.env` file:

```bash
# API Keys
ALPACA_API_KEY=your_alpaca_key
ALPACA_SECRET_KEY=your_alpaca_secret
GROK_API_KEY=your_grok_key
FINNHUB_API_KEY=your_finnhub_key

# Redis
REDIS_PASSWORD=strong_password_here

# Postgres
POSTGRES_PASSWORD=strong_password_here

# Bot Configuration
BOT_MODE=paper  # or 'live' for real trading
```

### 4. SSL Certificates

For HTTPS, create SSL certificates:

```bash
mkdir -p nginx/ssl
# Use Let's Encrypt or your own certificates
certbot certonly --standalone -d your-domain.com
cp /etc/letsencrypt/live/your-domain.com/fullchain.pem nginx/ssl/
cp /etc/letsencrypt/live/your-domain.com/privkey.pem nginx/ssl/
```

### 5. Deploy Backend

```bash
# Build and start all services
docker-compose -f docker-compose.remote.yml up -d

# Check service status
docker-compose -f docker-compose.remote.yml ps

# View logs
docker-compose -f docker-compose.remote.yml logs -f ml_worker
docker-compose -f docker-compose.remote.yml logs -f trading_bot
```

### 6. Initialize Database

```bash
# Create initial database schema
docker exec -it qt_trade_postgres psql -U qt_user -d qt_trade -f /docker-entrypoint-initdb.d/init.sql
```

## Local Frontend Setup

### 1. Build Qt Frontend

```bash
# Windows (using Qt Creator or CMake)
mkdir build
cd build
cmake .. -DCMAKE_PREFIX_PATH=C:/Qt/6.6.1/msvc2019_64
cmake --build . --config Release

# Linux
mkdir build
cd build
cmake .. -DCMAKE_PREFIX_PATH=/opt/Qt/6.6.1/gcc_64
make -j$(nproc)
```

### 2. Configure Frontend

Create `config.ini` in the application directory:

```ini
[Redis]
Host=your-server-ip
Port=6380
Password=your_redis_password

[Trading]
DefaultAggressiveness=0.5
MaxHoldingDays=7
RefreshInterval=5000
```

### 3. Run Frontend

```bash
# Windows
./QtTradeFrontend.exe

# Linux
./QtTradeFrontend
```

## Feature Configuration

### Bot Aggressiveness Settings

The bot aggressiveness slider controls:

- **0.0 - 0.3**: Conservative
  - Minimum confidence: 85%
  - Buy threshold: 3%+ predicted gain
  - Small position sizes (5-10% of max)

- **0.4 - 0.6**: Balanced (Default)
  - Minimum confidence: 70%
  - Buy threshold: 2%+ predicted gain
  - Medium position sizes (10-15% of max)

- **0.7 - 1.0**: Aggressive
  - Minimum confidence: 60%
  - Buy threshold: 1%+ predicted gain
  - Large position sizes (15-20% of max)

### 7-Day Trading Rules

1. **Automatic Sell**: All positions are automatically closed after 7 days
2. **Stop Loss**: Default 5% (configurable)
3. **Take Profit**: Default 15% (configurable)
4. **Signal Frequency**: Checked every 5 minutes

### ML Predictions

- **Update Frequency**: Every hour
- **Prediction Horizon**: 7 days (2016 5-minute intervals)
- **Confidence Calculation**: Based on volatility, volume, and model accuracy
- **Retraining**: Daily at 09:00 UTC or when portfolio diverges >15%

## Monitoring

### Check System Status

```bash
# Redis connection
redis-cli -h localhost -p 6380 -a your_password ping

# View ML status
redis-cli -h localhost -p 6380 -a your_password get ml_status

# View bot actions
redis-cli -h localhost -p 6380 -a your_password get bot_actions

# Service health
docker-compose -f docker-compose.remote.yml ps
```

### View Logs

```bash
# All services
docker-compose -f docker-compose.remote.yml logs -f

# Specific service
docker-compose -f docker-compose.remote.yml logs -f ml_worker
docker-compose -f docker-compose.remote.yml logs -f trading_bot
```

## Troubleshooting

### Frontend Can't Connect

1. Check Redis is accessible:
   ```bash
   telnet your-server-ip 6380
   ```

2. Verify firewall rules:
   ```bash
   sudo ufw allow 6380/tcp
   ```

3. Check Redis password in both frontend and backend configs

### ML Predictions Not Updating

1. Check ML worker logs:
   ```bash
   docker-compose -f docker-compose.remote.yml logs ml_worker
   ```

2. Verify data availability:
   ```bash
   redis-cli -h localhost -p 6380 -a your_password keys "chart_data_7d_*"
   ```

3. Manually trigger training:
   ```bash
   redis-cli -h localhost -p 6380 -a your_password set manual_trigger_ml true
   ```

### Bot Not Trading

1. Check bot configuration:
   ```bash
   redis-cli -h localhost -p 6380 -a your_password get bot_config
   ```

2. Verify Alpaca credentials:
   ```bash
   docker-compose -f docker-compose.remote.yml logs trading_bot | grep "API"
   ```

3. Check account status and buying power

## Security Best Practices

1. **Use Strong Passwords**: Generate secure passwords for Redis and PostgreSQL
2. **Firewall Rules**: Only allow necessary ports
3. **SSL/TLS**: Always use HTTPS for API communications
4. **API Key Security**: Never commit API keys to version control
5. **Regular Updates**: Keep Docker images and dependencies updated
6. **Monitoring**: Set up alerts for unusual trading activity

## Backup and Recovery

### Backup Data

```bash
# Backup Redis
docker exec qt_trade_redis redis-cli -a your_password --rdb /data/backup.rdb

# Backup PostgreSQL
docker exec qt_trade_postgres pg_dump -U qt_user qt_trade > backup.sql

# Backup ML models
tar -czf ml_models_backup.tar.gz /app/ml_models/
```

### Restore Data

```bash
# Restore Redis
docker cp backup.rdb qt_trade_redis:/data/dump.rdb
docker restart qt_trade_redis

# Restore PostgreSQL
docker exec -i qt_trade_postgres psql -U qt_user qt_trade < backup.sql

# Restore ML models
tar -xzf ml_models_backup.tar.gz -C /app/
```

## Performance Tuning

### Redis Optimization

Edit Redis configuration:

```bash
maxmemory 2gb
maxmemory-policy allkeys-lru
save 900 1
save 300 10
save 60 10000
```

### ML Worker Optimization

Adjust in `ml_worker.py`:

```python
# Reduce prediction frequency for better performance
PREDICTION_INTERVAL = 3600  # 1 hour instead of 5 minutes

# Limit concurrent symbol processing
MAX_CONCURRENT_SYMBOLS = 3
```

### Trading Bot Optimization

```python
# Batch order submissions
BATCH_SIZE = 5

# Cache account info
ACCOUNT_CACHE_TTL = 60  # seconds
```

## Support

For issues or questions:
1. Check logs first
2. Review troubleshooting section
3. Consult the Redis schema documentation
4. Check ml.md for ML-specific details