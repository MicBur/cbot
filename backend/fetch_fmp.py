from __future__ import annotations

import os
import time
from typing import Dict, List
import requests
from tenacity import retry, stop_after_attempt, wait_exponential
from common.config import Config
from common.logger import get_logger
from common.redis_utils import build_redis, set_json
from postgres_writer import PostgresWriter


logger = get_logger("fetch_fmp")


class FMPClient:
    def __init__(self, api_key: str):
        self.api_key = api_key
        self.base = "https://financialmodelingprep.com/api/v3"

    @retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=1, max=8))
    def get_quote(self, symbols: List[str]) -> List[Dict]:
        syms = ",".join(symbols)
        url = f"{self.base}/quote/{syms}?apikey={self.api_key}"
        r = requests.get(url, timeout=15)
        r.raise_for_status()
        return r.json()

    @retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=1, max=8))
    def get_intraday(self, symbol: str, interval: str = "5min") -> List[Dict]:
        url = f"{self.base}/historical-chart/{interval}/{symbol}?apikey={self.api_key}"
        r = requests.get(url, timeout=20)
        r.raise_for_status()
        data = r.json()
        # Map to common schema {t,o,h,l,c,v}
        candles = []
        for d in reversed(data):  # oldest -> newest
            t = int(time.mktime(time.strptime(d["date"], "%Y-%m-%d %H:%M:%S")))
            candles.append({
                "t": t,
                "o": float(d["open"]),
                "h": float(d["high"]),
                "l": float(d["low"]),
                "c": float(d["close"]),
                "v": float(d.get("volume") or 0)
            })
        return candles


def run_once(cfg: Config, fmp: FMPClient, pg: PostgresWriter | None) -> None:
    r = build_redis(cfg)
    # Quotes -> market_data
    try:
        quotes = fmp.get_quote(cfg.symbols)
        market = {}
        for q in quotes:
            sym = q.get("symbol")
            if not sym:
                continue
            price = float(q.get("price") or 0)
            change = float(q.get("change") or 0)
            change_pct = float(q.get("changesPercentage") or 0) / 100.0
            market[sym] = {
                "price": price,
                "change": change,
                "change_percent": change_pct,
            }
        if market:
            set_json(r, "market_data", market)
    except Exception as e:
        logger.exception("quote fetch failed: %s", e)

    # Intraday candles per symbol
    for sym in cfg.symbols:
        try:
            candles = fmp.get_intraday(sym, interval="5min")
            set_json(r, f"chart_data_{sym}", candles)
            if pg:
                pg.upsert_candles(sym, candles)
        except Exception as e:
            logger.exception("candles fetch failed for %s: %s", sym, e)


def main() -> None:
    cfg = Config()
    if not cfg.fmp_api_key:
        raise SystemExit("FMP_API_KEY missing")
    fmp = FMPClient(cfg.fmp_api_key)
    pg = PostgresWriter(cfg) if os.getenv("ENABLE_POSTGRES", "1") == "1" else None
    interval = cfg.fetch_interval_seconds
    logger.info("FMP fetcher started for %s, interval=%ss", ",".join(cfg.symbols), interval)
    while True:
        run_once(cfg, fmp, pg)
        time.sleep(interval)


if __name__ == "__main__":
    main()

