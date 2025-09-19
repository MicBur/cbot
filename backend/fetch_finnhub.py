from __future__ import annotations

import os
import time
from typing import Dict, List
import finnhub
from tenacity import retry, stop_after_attempt, wait_exponential
from common.config import Config
from common.logger import get_logger
from common.redis_utils import build_redis, set_json
from postgres_writer import PostgresWriter


logger = get_logger("fetch_finnhub")


class FinnhubClient:
    def __init__(self, api_key: str):
        self.client = finnhub.Client(api_key=api_key)

    @retry(stop=stop_after_attempt(3), wait=wait_exponential(min=1, max=8))
    def get_quote(self, symbol: str) -> Dict:
        return self.client.quote(symbol)

    @retry(stop=stop_after_attempt(3), wait=wait_exponential(min=1, max=8))
    def get_candles(self, symbol: str, resolution: str = "5", count: int = 288) -> List[Dict]:
        # 5=5min; get last N candles using to=now and count windows back
        now = int(time.time())
        frm = now - count * 300
        data = self.client.stock_candles(symbol, resolution, frm, now)
        if data.get("s") != "ok":
            return []
        t = data["t"]
        o = data["o"]
        h = data["h"]
        l = data["l"]
        c = data["c"]
        v = data.get("v") or [0] * len(t)
        return [
            {"t": int(t[i]), "o": float(o[i]), "h": float(h[i]), "l": float(l[i]), "c": float(c[i]), "v": float(v[i])}
            for i in range(len(t))
        ]


def run_once(cfg: Config, fh: FinnhubClient, pg: PostgresWriter | None) -> None:
    r = build_redis(cfg)
    # Quotes
    market: Dict[str, Dict] = {}
    for sym in cfg.symbols:
        try:
            q = fh.get_quote(sym)
            price = float(q.get("c") or 0)
            prev_close = float(q.get("pc") or 0)
            change = price - prev_close if prev_close else 0.0
            change_pct = (change / prev_close) if prev_close else 0.0
            market[sym] = {"price": price, "change": change, "change_percent": change_pct}
        except Exception as e:
            logger.exception("quote failed for %s: %s", sym, e)
    if market:
        set_json(r, "market_data", market)

    # Candles
    for sym in cfg.symbols:
        try:
            candles = fh.get_candles(sym, resolution="5", count=288)
            set_json(r, f"chart_data_{sym}", candles)
            if pg:
                pg.upsert_candles(sym, candles)
        except Exception as e:
            logger.exception("candles failed for %s: %s", sym, e)


def main() -> None:
    cfg = Config()
    if not cfg.finnhub_api_key:
        raise SystemExit("FINNHUB_API_KEY missing")
    fh = FinnhubClient(cfg.finnhub_api_key)
    pg = PostgresWriter(cfg) if os.getenv("ENABLE_POSTGRES", "1") == "1" else None
    interval = cfg.fetch_interval_seconds
    logger.info("Finnhub fetcher started for %s, interval=%ss", ",".join(cfg.symbols), interval)
    while True:
        run_once(cfg, fh, pg)
        time.sleep(interval)


if __name__ == "__main__":
    main()

