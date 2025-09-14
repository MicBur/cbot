import os
import json
import redis
from typing import Any, Optional

class RedisClient:
    def __init__(self, host: str = None, port: int = None, password: Optional[str] = None, db: int = 0, decode_responses: bool = True):
        self.host = host or os.getenv("REDIS_HOST", "127.0.0.1")
        self.port = port or int(os.getenv("REDIS_PORT", "6380"))
        self.password = password or os.getenv("REDIS_PASSWORD")
        self.db = db
        self._r = redis.Redis(host=self.host, port=self.port, password=self.password, db=self.db, decode_responses=decode_responses)

    def ping(self) -> bool:
        try:
            return self._r.ping()
        except redis.RedisError:
            return False

    def get_json(self, key: str) -> Any:
        try:
            raw = self._r.get(key)
            if raw is None:
                return None
            try:
                return json.loads(raw)
            except json.JSONDecodeError:
                return None
        except redis.RedisError:
            return None

    def set_json(self, key: str, value: Any) -> bool:
        try:
            self._r.set(key, json.dumps(value))
            return True
        except redis.RedisError:
            return False
