from __future__ import annotations

import time
from typing import Dict, List
import yfinance as yf
from common.config import Config
from common.logger import get_logger
from common.redis_utils import build_redis, set_json
from postgres_writer import PostgresWriter


logger = get_logger("fetch_yfinance")


def _to_epoch(ts) -> int:
    return int(ts.timestamp())


def build_market_snapshot(symbols: List[str]) -> Dict[str, Dict]:
    res: Dict[str, Dict] = {}
    tickers = yf.Tickers(" ".join(symbols))
    for sym in symbols:
        t = tickers.tickers.get(sym)
        if not t:
            continue
        info = {}
        try:
            # fast access via history
            hist = t.history(period="2d", interval="1d")
            if not hist.empty:
                price = float(hist["Close"].iloc[-1])
                prev = float(hist["Close"].iloc[-2]) if len(hist) > 1 else price
                change = price - prev
                pct = (change / prev) if prev else 0.0
                info = {"price": price, "change": change, "change_percent": pct}
        except Exception:
            pass
        if info:
            res[sym] = info
    return res


def fetch_intraday_5m(symbol: str, limit: int = 288) -> List[Dict]:
    t = yf.Ticker(symbol)
    df = t.history(period="7d", interval="5m")
    candles: List[Dict] = []
    if df is None or df.empty:
        return candles
    df = df.tail(limit)
    for idx, row in df.iterrows():
        candles.append({
            "t": _to_epoch(idx.to_pydatetime()),
            "o": float(row["Open"]),
            "h": float(row["High"]),
            "l": float(row["Low"]),
            "c": float(row["Close"]),
            "v": float(row.get("Volume") or 0)
        })
    return candles


def run_once(cfg: Config, pg: PostgresWriter | None) -> None:
    r = build_redis(cfg)

    # Market snapshot
    market = build_market_snapshot(cfg.symbols)
    if market:
        set_json(r, "market_data", market)

    # Candles per symbol
    for sym in cfg.symbols:
        try:
            candles = fetch_intraday_5m(sym, limit=288)
            set_json(r, f"chart_data_{sym}", candles)
            if pg:
                pg.upsert_candles(sym, candles)
        except Exception as e:
            logger.exception("yfinance candles failed for %s: %s", sym, e)


def main() -> None:
    cfg = Config()
    pg = PostgresWriter(cfg) if (cfg.pg_host and cfg.pg_db and cfg.pg_user) else None
    interval = cfg.fetch_interval_seconds
    logger.info("yfinance fetcher started for %s, interval=%ss", ",".join(cfg.symbols), interval)
    while True:
        run_once(cfg, pg)
        time.sleep(interval)


if __name__ == "__main__":
    main()

