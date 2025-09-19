from __future__ import annotations

import json
from typing import Any, Optional
import redis
from .config import Config


def build_redis(cfg: Config) -> redis.Redis:
    return redis.Redis(
        host=cfg.redis_host,
        port=cfg.redis_port,
        password=cfg.redis_password,
        decode_responses=True,
    )


def set_json(r: redis.Redis, key: str, value: Any, ex: Optional[int] = None) -> None:
    r.set(key, json.dumps(value), ex=ex)


def get_json(r: redis.Redis, key: str) -> Any:
    raw = r.get(key)
    return json.loads(raw) if raw else None

