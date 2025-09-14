import os
import json
import logging
from datetime import datetime, timedelta

from dotenv import load_dotenv
from celery import Celery
from celery.schedules import crontab

import requests
import redis
import psycopg2

try:
    from autogluon.tabular import TabularPredictor  # type: ignore
except Exception:  # pragma: no cover - optional heavy dependency
    TabularPredictor = None  # type: ignore

try:
    from xai_sdk import Client as XaiClient  # type: ignore
    from xai_sdk.chat import user as xai_user, system as xai_system  # type: ignore
except Exception:  # pragma: no cover
    XaiClient = None  # type: ignore
    xai_user = None
    xai_system = None


# --- Environment ---
load_dotenv()

REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:pass123@localhost:5432/qt_trade")

FINNHUB_API_KEY = os.getenv("FINNHUB_API_KEY")
FMP_API_KEY = os.getenv("FMP_API_KEY")
ALPACA_API_KEY = os.getenv("ALPACA_API_KEY")
ALPACA_SECRET = os.getenv("ALPACA_SECRET")
XAI_API_KEY = os.getenv("XAI_API_KEY")

TICKERS = [
    "AAPL", "NVDA", "MSFT", "TSLA", "AMZN", "META", "GOOGL", "BRK.B", "AVGO", "JPM",
    "LLY", "V", "XOM", "PG", "UNH", "MA", "JNJ", "COST", "HD", "BAC",
]


# --- Logging ---
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger("worker")


# --- Celery ---
app = Celery("worker", broker=REDIS_URL, backend=REDIS_URL)


# --- Clients ---
def get_redis_client() -> "redis.Redis":
    return redis.from_url(REDIS_URL, decode_responses=True)


def get_db_connection() -> psycopg2.extensions.connection:  # type: ignore
    return psycopg2.connect(DATABASE_URL)


def safe_set_json(r: "redis.Redis", key: str, value) -> None:
    try:
        r.set(key, json.dumps(value))
    except Exception as exc:  # pragma: no cover
        logger.error("Redis set failed for %s: %s", key, exc)


def _alpaca_headers() -> dict:
    return {
        "APCA-API-KEY-ID": ALPACA_API_KEY or "",
        "APCA-API-SECRET-KEY": ALPACA_SECRET or "",
    }


# --- Tasks ---
@app.task
def fetch_data() -> dict:
    """Fetch current quotes for tickers from Finnhub and persist to Redis and DB."""
    if not FINNHUB_API_KEY:
        logger.warning("FINNHUB_API_KEY not set; skipping fetch_data")
        return {}

    r = get_redis_client()
    conn = get_db_connection()
    cur = conn.cursor()
    aggregated: dict = {}

    for ticker in TICKERS:
        try:
            url = f"https://finnhub.io/api/v1/quote?symbol={ticker}&token={FINNHUB_API_KEY}"
            resp = requests.get(url, timeout=30)
            if resp.status_code != 200:
                logger.warning("Finnhub quote failed %s: %s", ticker, resp.text)
                continue
            q = resp.json()
            aggregated[ticker] = {
                "price": q.get("c"),
                "change": q.get("d"),
                "change_percent": q.get("dp"),
            }

            # Insert into DB (15m bars approximated from quote; volume mocked)
            cur.execute(
                """
                INSERT INTO market_data (time, ticker, open, high, low, close, volume)
                VALUES (NOW(), %s, %s, %s, %s, %s, %s)
                ON CONFLICT (time, ticker) DO NOTHING
                """,
                (ticker, q.get("o"), q.get("h"), q.get("l"), q.get("c"), 1000000),
            )
        except Exception as exc:
            logger.error("fetch_data error for %s: %s", ticker, exc)

    conn.commit()
    cur.close()
    conn.close()

    safe_set_json(r, "market_data", aggregated)
    return aggregated


@app.task
def fetch_portfolio() -> dict:
    """Fetch portfolio positions and equity from Alpaca; store in Redis and DB."""
    headers = _alpaca_headers()
    r = get_redis_client()
    conn = get_db_connection()
    cur = conn.cursor()

    positions: list = []
    equity_value = None
    try:
        pos_resp = requests.get("https://paper-api.alpaca.markets/v2/positions", headers=headers, timeout=30)
        positions = pos_resp.json() if pos_resp.status_code == 200 else []
        safe_set_json(r, "portfolio_positions", positions)

        for pos in positions:
            cur.execute(
                """
                INSERT INTO portfolio_positions (ticker, qty, avg_price, side)
                VALUES (%s, %s, %s, %s)
                ON CONFLICT (ticker) DO UPDATE
                  SET qty=EXCLUDED.qty, avg_price=EXCLUDED.avg_price, side=EXCLUDED.side
                """,
                (
                    pos.get("symbol") or pos.get("ticker"),
                    float(pos.get("qty", 0)),
                    float(pos.get("avg_entry_price") or pos.get("avg_price") or 0),
                    pos.get("side", ""),
                ),
            )

        acct_resp = requests.get("https://paper-api.alpaca.markets/v2/account", headers=headers, timeout=30)
        if acct_resp.status_code == 200 and isinstance(acct_resp.json(), dict):
            equity_value = acct_resp.json().get("equity")
            safe_set_json(
                r,
                "portfolio_equity",
                [{"timestamp": datetime.utcnow().isoformat(), "equity_value": equity_value}],
            )
            cur.execute(
                "INSERT INTO portfolio_equity (time, equity_value) VALUES (NOW(), %s)",
                (float(equity_value) if equity_value is not None else None,),
            )

        conn.commit()
    except Exception as exc:
        logger.error("fetch_portfolio error: %s", exc)
    finally:
        cur.close()
        conn.close()

    return {"positions": positions, "equity": equity_value}


@app.task
def fetch_historical_data() -> str:
    if not FINNHUB_API_KEY:
        logger.warning("FINNHUB_API_KEY not set; skipping fetch_historical_data")
        return "FINNHUB_API_KEY missing"

    conn = get_db_connection()
    cur = conn.cursor()
    end_time = int(datetime.utcnow().timestamp())
    start_time = int((datetime.utcnow() - timedelta(days=30)).timestamp())

    for ticker in TICKERS:
        try:
            url = (
                f"https://finnhub.io/api/v1/stock/candle?symbol={ticker}&resolution=15"
                f"&from={start_time}&to={end_time}&token={FINNHUB_API_KEY}"
            )
            resp = requests.get(url, timeout=60)
            if resp.status_code != 200:
                logger.warning("Finnhub candle failed %s: %s", ticker, resp.text)
                continue
            candles = resp.json()
            if not isinstance(candles, dict) or candles.get("s") != "ok":
                continue
            for i, ts in enumerate(candles.get("t", [])):
                cur.execute(
                    """
                    INSERT INTO market_data (time, ticker, open, high, low, close, volume)
                    VALUES (to_timestamp(%s), %s, %s, %s, %s, %s, %s)
                    ON CONFLICT (time, ticker) DO NOTHING
                    """,
                    (
                        ts,
                        ticker,
                        candles.get("o", [None])[i],
                        candles.get("h", [None])[i],
                        candles.get("l", [None])[i],
                        candles.get("c", [None])[i],
                        candles.get("v", [None])[i],
                    ),
                )
        except Exception as exc:
            logger.error("fetch_historical_data error for %s: %s", ticker, exc)

    conn.commit()
    cur.close()
    conn.close()
    logger.info("Historical data fetched successfully")
    return "Historical data updated"


@app.task
def train_model() -> str:
    r = get_redis_client()
    if TabularPredictor is None:
        safe_set_json(r, "ml_status", {"training_active": False, "last_error": "AutoGluon not installed"})
        logger.warning("AutoGluon not available; skipping training")
        return "AutoGluon not available"

    import pandas as pd  # lazy import
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute(
        """
        SELECT ticker, time, open, high, low, close, volume,
               LAG(close, 1) OVER (PARTITION BY ticker ORDER BY time) as prev_close,
               LAG(close, 5) OVER (PARTITION BY ticker ORDER BY time) as prev_close_5,
               LAG(close, 15) OVER (PARTITION BY ticker ORDER BY time) as prev_close_15
        FROM market_data
        WHERE time >= NOW() - INTERVAL '7 days'
        ORDER BY ticker, time
        """
    )
    rows = cur.fetchall()
    cur.close()
    conn.close()

    if len(rows) < 100:
        msg = f"Insufficient data: {len(rows)} rows"
        logger.warning(msg)
        return msg

    df = pd.DataFrame(
        rows,
        columns=[
            "ticker",
            "time",
            "open",
            "high",
            "low",
            "close",
            "volume",
            "prev_close",
            "prev_close_5",
            "prev_close_15",
        ],
    )

    df["price_change"] = df["close"] - df["prev_close"]
    df["price_change_5"] = df["close"] - df["prev_close_5"]
    df["price_change_15"] = df["close"] - df["prev_close_15"]
    df["volatility"] = (df["high"] - df["low"]) / df["close"].replace(0, float("nan"))
    df["hour"] = pd.to_datetime(df["time"]).dt.hour
    df["day_of_week"] = pd.to_datetime(df["time"]).dt.dayofweek
    df["target"] = df.groupby("ticker")["close"].shift(-4)
    df = df.dropna()

    if len(df) < 50:
        msg = f"Insufficient clean data: {len(df)} rows"
        logger.warning(msg)
        return msg

    df = pd.get_dummies(df, columns=["ticker"], prefix="ticker")
    feature_columns = [c for c in df.columns if c not in ["time", "target"]]
    train_data = df[feature_columns + ["target"]]

    try:
        predictor = TabularPredictor(label="target", path="./autogluon_model", eval_metric="mean_absolute_error")
        predictor = predictor.fit(train_data, time_limit=300)
        safe_set_json(get_redis_client(), "model_trained", True)
        safe_set_json(get_redis_client(), "model_path", "./autogluon_model")
        logger.info("Model trained successfully with %s samples", len(train_data))
        return f"Model trained with {len(train_data)} samples"
    except Exception as exc:
        logger.error("Training failed: %s", exc)
        return f"Training failed: {exc}"


@app.task
def trade_bot() -> None:
    r = get_redis_client()
    try:
        raw = r.get("market_data")
        market = json.loads(raw) if raw else {}
    except Exception:
        market = {}

    headers = _alpaca_headers()
    for ticker in TICKERS:
        current_price = (market.get(ticker) or {}).get("price") or 0
        if not current_price:
            continue
        predicted_price = current_price * 1.06  # placeholder until predictor inference added
        try:
            if predicted_price > current_price * 1.05:
                order = {"symbol": ticker, "qty": 1, "side": "buy", "type": "market", "time_in_force": "gtc"}
                requests.post("https://paper-api.alpaca.markets/v2/orders", json=order, headers=headers, timeout=30)
            elif predicted_price < current_price * 0.95:
                order = {"symbol": ticker, "qty": 1, "side": "sell", "type": "market", "time_in_force": "gtc"}
                requests.post("https://paper-api.alpaca.markets/v2/orders", json=order, headers=headers, timeout=30)
        except Exception as exc:
            logger.error("trade_bot order error for %s: %s", ticker, exc)


@app.task
def fetch_grok_recommendations() -> object:
    """Fetch Top-10 recommendations via xai-sdk if available, store in Redis and DB."""
    if XaiClient is None or not XAI_API_KEY:
        logger.warning("xai-sdk not available or XAI_API_KEY missing; skipping grok task")
        return None

    try:
        client = XaiClient(api_key=XAI_API_KEY)
        chat = client.chat.create(model="grok-4-0709", temperature=0.1)
        chat.append(xai_system("You are a helpful assistant with access to real-time search. Give the top 10 US stocks with highest 7-day gain probability. Output JSON with ticker, score, reason."))
        chat.append(xai_user("Gib die Top 10 US-Aktien mit höchster 7-Tage-Gewinnwahrscheinlichkeit als JSON."))
        response = chat.sample()
        try:
            top10 = json.loads(response.content)
        except Exception:
            top10 = response.content
    except Exception as exc:
        logger.error("xai-sdk call failed: %s", exc)
        return None

    r = get_redis_client()
    safe_set_json(r, "grok_top10", top10)

    try:
        conn = get_db_connection()
        cur = conn.cursor()
        if isinstance(top10, list):
            for rec in top10:
                cur.execute(
                    """
                    INSERT INTO grok_recommendations (time, ticker, score, reason)
                    VALUES (NOW(), %s, %s, %s)
                    """,
                    (rec.get("ticker"), rec.get("score"), rec.get("reason")),
                )
            conn.commit()
        cur.close()
        conn.close()
    except Exception as exc:  # pragma: no cover
        logger.error("Persisting grok_top10 failed: %s", exc)

    return top10


# --- Beat schedule ---
app.conf.beat_schedule = {
    "train-daily": {
        "task": "worker.train_model",
        "schedule": crontab(hour=9, minute=0),
    },
    "grok-top10-daily": {
        "task": "worker.fetch_grok_recommendations",
        "schedule": crontab(hour=9, minute=5),
    },
    "portfolio-sync": {
        "task": "worker.fetch_portfolio",
        "schedule": crontab(minute="*/5"),
    },
    "tradebot-auto": {
        "task": "worker.trade_bot",
        "schedule": crontab(minute="*/10"),
    },
}

