# Backend Services (Dockerized)

This backend provides market data ingestion (FMP, Finnhub, yfinance), ML worker and trading bot, with Redis and Postgres via docker-compose.

## Services
- redis: key/value store for frontend consumption
- postgres: optional persistence for candles/predictions
- fetch-fmp: Financial Modeling Prep quotes + 5m candles
- fetch-finnhub: Finnhub quotes + 5m candles
- fetch-yfinance: yfinance 5m candles and daily snapshot
- ml-worker: generates predictions (uses Redis)
- trading-bot: places orders via Alpaca (uses Redis)

## Quick start
1) Copy env template
```
cp .env.example .env
```
2) Set API keys in `.env` (FMP, FINNHUB, ALPACA). Adjust symbols if needed.
3) Launch stack
```
docker compose up --build -d
```
4) Logs
```
docker compose logs -f fetch-fmp fetch-finnhub fetch-yfinance ml-worker trading-bot
```

## Redis keys used
- market_data: consolidated quotes {SYMBOL: {price, change, change_percent}}
- chart_data_<SYMBOL>: list of candles [{t,o,h,l,c,v}]
- predictions_<SYMBOL>: list of predictions [{t,v,conf}]
- trading_signals_<SYMBOL>: recent buy/sell signals
- api_status: "valid" when trading bot is authenticated and reachable

## Postgres schema
- candles(symbol, t, o, h, l, c, v)
- predictions(symbol, t, v, conf, source)

Toggle Postgres with `ENABLE_POSTGRES=1|0`.

## Notes
- Default Redis port inside compose is 6379; frontend expects 6380 by default. Run the frontend with `--redis-port 6380` or change `.env`/frontend defaults.
- Data providers have rate limits. The fetchers retry and backoff modestly; consider increasing `FETCH_INTERVAL_SECONDS` for production.