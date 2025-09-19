from __future__ import annotations

from dataclasses import dataclass
from typing import Iterable, Dict, Any
from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine
from common.config import Config
from common.logger import get_logger


logger = get_logger("postgres_writer")


@dataclass
class PostgresWriter:
    cfg: Config
    engine: Engine | None = None

    def __post_init__(self) -> None:
        self.engine = create_engine(self.cfg.pg_dsn, pool_pre_ping=True)
        self._ensure_schema()

    def _ensure_schema(self) -> None:
        with self.engine.begin() as conn:
            conn.execute(
                text(
                    """
                    CREATE TABLE IF NOT EXISTS candles (
                      symbol TEXT NOT NULL,
                      t BIGINT NOT NULL,
                      o DOUBLE PRECISION NOT NULL,
                      h DOUBLE PRECISION NOT NULL,
                      l DOUBLE PRECISION NOT NULL,
                      c DOUBLE PRECISION NOT NULL,
                      v DOUBLE PRECISION,
                      PRIMARY KEY(symbol, t)
                    );
                    CREATE INDEX IF NOT EXISTS idx_candles_symbol_t ON candles(symbol, t);

                    CREATE TABLE IF NOT EXISTS predictions (
                      symbol TEXT NOT NULL,
                      t BIGINT NOT NULL,
                      v DOUBLE PRECISION NOT NULL,
                      conf DOUBLE PRECISION,
                      source TEXT,
                      PRIMARY KEY(symbol, t)
                    );
                    CREATE INDEX IF NOT EXISTS idx_predictions_symbol_t ON predictions(symbol, t);
                    """
                )
            )

    def upsert_candles(self, symbol: str, candles: Iterable[Dict[str, Any]]) -> None:
        if not candles:
            return
        rows = [
            {
                "symbol": symbol,
                "t": int(c["t"]),
                "o": float(c["o"]),
                "h": float(c["h"]),
                "l": float(c["l"]),
                "c": float(c["c"]),
                "v": float(c.get("v") or 0),
            }
            for c in candles
        ]
        stmt = text(
            """
            INSERT INTO candles(symbol,t,o,h,l,c,v)
            VALUES (:symbol,:t,:o,:h,:l,:c,:v)
            ON CONFLICT(symbol,t) DO UPDATE SET o=EXCLUDED.o,h=EXCLUDED.h,l=EXCLUDED.l,c=EXCLUDED.c,v=EXCLUDED.v
            """
        )
        with self.engine.begin() as conn:
            conn.execute(stmt, rows)

    def upsert_predictions(self, symbol: str, preds: Iterable[Dict[str, Any]], source: str) -> None:
        if not preds:
            return
        rows = [
            {
                "symbol": symbol,
                "t": int(p["t"]),
                "v": float(p["v"]),
                "conf": float(p.get("conf") or 0),
                "source": source,
            }
            for p in preds
        ]
        stmt = text(
            """
            INSERT INTO predictions(symbol,t,v,conf,source)
            VALUES (:symbol,:t,:v,:conf,:source)
            ON CONFLICT(symbol,t) DO UPDATE SET v=EXCLUDED.v, conf=EXCLUDED.conf, source=EXCLUDED.source
            """
        )
        with self.engine.begin() as conn:
            conn.execute(stmt, rows)

