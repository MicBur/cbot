import os
import subprocess
import json
import redis
import psycopg2
from datetime import datetime

API_KEY = os.getenv("XAI_API_KEY", "")
MODEL = os.getenv("XAI_MODEL", "grok-4-latest")
REDIS_URL = os.getenv("REDIS_URL", "redis://:pass123@localhost:6379/0")
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:pass123@localhost:5432/qt_trade")

if not API_KEY:
    raise SystemExit("XAI_API_KEY is not set")

prompt = {
    "messages": [
        {"role": "system", "content": "You are a helpful assistant with access to real-time search. Give the top 10 US stocks with highest 7-day gain probability. Output JSON with ticker, score, reason."},
        {"role": "user", "content": "Gib die Top 10 US-Aktien mit h\u00f6chster 7-Tage-Gewinnwahrscheinlichkeit als JSON."}
    ],
    "model": MODEL,
    "stream": False,
    "temperature": 0
}

curl_cmd = [
    "curl", "https://api.x.ai/v1/chat/completions",
    "-H", "Content-Type: application/json",
    "-H", f"Authorization: Bearer {API_KEY}",
    "-d", json.dumps(prompt)
]
result = subprocess.run(curl_cmd, capture_output=True, text=True)
response = result.stdout or result.stderr

try:
    data = json.loads(response)
    top10 = None
    if isinstance(data, dict) and data.get("choices"):
        msg = data["choices"][0]["message"]["content"]
        top10 = json.loads(msg) if isinstance(msg, str) else msg
except Exception:
    top10 = None

r = redis.from_url(REDIS_URL, decode_responses=True)
if top10 is not None:
    r.set("grok_top10", json.dumps(top10))

def save_to_postgres(top10_list):
    if not isinstance(top10_list, list):
        return
    conn = psycopg2.connect(DATABASE_URL)
    cur = conn.cursor()
    for rec in top10_list:
        cur.execute(
            """
            INSERT INTO grok_recommendations (time, ticker, score, reason)
            VALUES (%s, %s, %s, %s)
            """,
            (datetime.now(), rec.get("ticker"), rec.get("score"), rec.get("reason"))
        )
    conn.commit()
    cur.close()
    conn.close()

save_to_postgres(top10)
print("Grok Top10 gespeichert.")

