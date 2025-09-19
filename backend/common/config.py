from dataclasses import dataclass
import os
from typing import List
from dotenv import load_dotenv


def _split_list(value: str) -> List[str]:
    if not value:
        return []
    return [s.strip() for s in value.split(",") if s.strip()]


load_dotenv(override=False)


@dataclass
class Config:
    redis_host: str = os.getenv("REDIS_HOST", "127.0.0.1")
    redis_port: int = int(os.getenv("REDIS_PORT", "6380"))
    redis_password: str | None = os.getenv("REDIS_PASSWORD")

    pg_user: str = os.getenv("POSTGRES_USER", "postgres")
    pg_password: str = os.getenv("POSTGRES_PASSWORD", "postgres")
    pg_host: str = os.getenv("POSTGRES_HOST", "postgres")
    pg_port: int = int(os.getenv("POSTGRES_PORT", "5432"))
    pg_db: str = os.getenv("POSTGRES_DB", "market")

    symbols: List[str] = None  # set in __post_init__
    fetch_interval_seconds: int = int(os.getenv("FETCH_INTERVAL_SECONDS", "300"))

    # Providers
    fmp_api_key: str | None = os.getenv("FMP_API_KEY")
    finnhub_api_key: str | None = os.getenv("FINNHUB_API_KEY")

    alpaca_api_key: str | None = os.getenv("ALPACA_API_KEY")
    alpaca_secret_key: str | None = os.getenv("ALPACA_SECRET_KEY")
    alpaca_mode: str = os.getenv("BOT_MODE", "paper")  # paper|live

    def __post_init__(self) -> None:
        default_syms = "AAPL,NVDA,MSFT,TSLA,AMZN,META,GOOGL"
        self.symbols = _split_list(os.getenv("SYMBOLS", default_syms))

    @property
    def pg_dsn(self) -> str:
        return (
            f"postgresql+psycopg2://{self.pg_user}:{self.pg_password}"
            f"@{self.pg_host}:{self.pg_port}/{self.pg_db}"
        )

