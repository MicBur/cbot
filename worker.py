import os
import json
from dotenv import load_dotenv
from celery import Celery
try:
    from xai_sdk import Client
    from xai_sdk.chat import user, system
except ImportError:
    Client = None
    user = None
    system = None
load_dotenv()
XAI_API_KEY = os.getenv("XAI_API_KEY")
# Celery initialisieren
app = Celery('worker', broker='redis://localhost:6379/0')
def grok_client():
    if not Client or not XAI_API_KEY:
        logging.error("xai-sdk nicht installiert oder XAI_API_KEY fehlt!")
        return None
    return Client(api_key=XAI_API_KEY)
@app.task
def fetch_grok_recommendations():
    """Holt Top-10 US-Aktien mit Grok 4 via xai-sdk, speichert in Redis und PostgreSQL."""
    client = grok_client()
    if not client:
        return None
    chat = client.chat.create(model="grok-4-0709", temperature=0.1)
    chat.append(system("You are a helpful assistant with access to real-time search. Give the top 10 US stocks with highest 7-day gain probability. Output JSON with ticker, score, reason."))
    chat.append(user("Gib die Top 10 US-Aktien mit höchster 7-Tage-Gewinnwahrscheinlichkeit als JSON."))
    response = chat.sample()
    try:
        top10 = json.loads(response.content)
    except Exception:
        top10 = response.content
    r.set('grok_top10', json.dumps(top10))
    cur = conn.cursor()
    if isinstance(top10, list):
        for rec in top10:
            cur.execute("""
                INSERT INTO grok_recommendations (time, ticker, score, reason)
                VALUES (NOW(), %s, %s, %s)
            """, (rec.get('ticker'), rec.get('score'), rec.get('reason')))
        conn.commit()
    logging.info("Grok Top-10 via xai-sdk gespeichert")
    return top10
@app.task
def fetch_grok_deepersearch():
    """Führt Grok 4 Deeper Search via xai-sdk aus, speichert in Redis und PostgreSQL."""
    client = grok_client()
    if not client:
        return None
    chat = client.chat.create(model="grok-4-0709", temperature=0.1)
    chat.append(system("You are a helpful assistant with access to real-time search. Use deeper search for current data."))
    chat.append(user("Führe eine deeper search durch: Gib mir die aktuellen Top 20 US-Aktien nach Marktkapitalisierung, inklusive Ticker, Name und 1-Tage-Change. Nutze Real-Time Search. Output JSON."))
    response = chat.sample()
    try:
        results = json.loads(response.content)
    except Exception:
        results = response.content
    r.set('grok_deepersearch', json.dumps(results))
    cur = conn.cursor()
    if isinstance(results, list):
        for res in results:
            cur.execute("""
                INSERT INTO grok_deepersearch_results (time, ticker, score, analysis, details)
                VALUES (NOW(), %s, %s, %s, %s)
            """, (res.get('ticker'), res.get('score'), res.get('analysis'), json.dumps(res.get('details'))))
        conn.commit()
    logging.info("Grok Deepersearch via xai-sdk gespeichert")
    return results
import os
import requests
import redis
import psycopg2
from autogluon.tabular import TabularPredictor
from celery import Celery
import logging
from datetime import datetime, timedelta

# Logging
logging.basicConfig(level=logging.INFO)

# Celery App
app = Celery('worker', broker=os.getenv('REDIS_URL'), backend=os.getenv('REDIS_URL'))

# Redis
r = redis.from_url(os.getenv('REDIS_URL'))

# Database
conn = psycopg2.connect(os.getenv('DATABASE_URL'))

# API Keys (from env)
FINNHUB_API_KEY = os.getenv('FINNHUB_API_KEY')
FMP_API_KEY = os.getenv('FMP_API_KEY')
ALPACA_API_KEY = os.getenv('ALPACA_API_KEY')
ALPACA_SECRET = os.getenv('ALPACA_SECRET')
GROK_API_KEY = os.getenv('GROK_API_KEY')

TICKERS = ['AAPL', 'NVDA', 'MSFT', 'TSLA', 'AMZN', 'META', 'GOOGL', 'BRK.B', 'AVGO', 'JPM', 'LLY', 'V', 'XOM', 'PG', 'UNH', 'MA', 'JNJ', 'COST', 'HD', 'BAC']

import os
import requests
import redis
import psycopg2
from autogluon.tabular import TabularPredictor
from celery import Celery
import logging
from datetime import datetime, timedelta

# Logging
logging.basicConfig(level=logging.INFO)

# Celery App
app = Celery('worker', broker=os.getenv('REDIS_URL'), backend=os.getenv('REDIS_URL'))

# Redis
r = redis.from_url(os.getenv('REDIS_URL'))

# Database
conn = psycopg2.connect(os.getenv('DATABASE_URL'))

# API Keys (from env)
FINNHUB_API_KEY = os.getenv('FINNHUB_API_KEY')
FMP_API_KEY = os.getenv('FMP_API_KEY')
ALPACA_API_KEY = os.getenv('ALPACA_API_KEY')
ALPACA_SECRET = os.getenv('ALPACA_SECRET')
GROK_API_KEY = os.getenv('GROK_API_KEY')

TICKERS = ['AAPL', 'NVDA', 'MSFT', 'TSLA', 'AMZN', 'META', 'GOOGL', 'BRK.B', 'AVGO', 'JPM', 'LLY', 'V', 'XOM', 'PG', 'UNH', 'MA', 'JNJ', 'COST', 'HD', 'BAC']

@app.task
def fetch_data():
    data = {}
    cur = conn.cursor()
    
    for ticker in TICKERS:
        # Fetch current quote from Finnhub
        url = f'https://finnhub.io/api/v1/quote?symbol={ticker}&token={FINNHUB_API_KEY}'
        response = requests.get(url)
        if response.status_code == 200:
            quote = response.json()
            data[ticker] = {
                'price': quote['c'],
                'change': quote['d'],
                'change_percent': quote['dp']
            }
            
            # Store in database for historical data
            cur.execute("""
                INSERT INTO market_data (time, ticker, open, high, low, close, volume)
                VALUES (NOW(), %s, %s, %s, %s, %s, %s)
            """, (ticker, quote['o'], quote['h'], quote['l'], quote['c'], 1000000))  # Mock volume
    
@app.task
def fetch_portfolio():
    """Holt Portfolio-Positionen und Equity von Alpaca, speichert in Redis und PostgreSQL."""
    headers = {
        'APCA-API-KEY-ID': ALPACA_API_KEY,
        'APCA-API-SECRET-KEY': ALPACA_SECRET
    }
    try:
        # Portfolio-Positionen
        pos_url = 'https://paper-api.alpaca.markets/v2/positions'
        pos_resp = requests.get(pos_url, headers=headers, timeout=30)
        positions = pos_resp.json() if pos_resp.status_code == 200 else []
        r.set('portfolio_positions', json.dumps(positions))
        cur = conn.cursor()
        for pos in positions:
            cur.execute("""
                INSERT INTO portfolio_positions (ticker, qty, avg_price, side)
                VALUES (%s, %s, %s, %s)
                ON CONFLICT (ticker) DO UPDATE SET qty=EXCLUDED.qty, avg_price=EXCLUDED.avg_price, side=EXCLUDED.side
            """, (pos.get('symbol'), pos.get('qty'), pos.get('avg_entry_price'), pos.get('side')))
        # Portfolio-Equity
        acct_url = 'https://paper-api.alpaca.markets/v2/account'
        acct_resp = requests.get(acct_url, headers=headers, timeout=30)
        equity = acct_resp.json().get('equity') if acct_resp.status_code == 200 else None
        if equity:
            r.set('portfolio_equity', json.dumps([{'timestamp': datetime.now().isoformat(), 'equity_value': equity}]))
            cur.execute("""
                INSERT INTO portfolio_equity (time, equity_value)
                VALUES (NOW(), %s)
            """, (equity,))
        conn.commit()
        logging.info("Portfolio und Equity erfolgreich gespeichert")
        return {'positions': positions, 'equity': equity}
    except Exception as e:
        logging.error(f"Alpaca Portfolio Exception: {str(e)}")
        return None
    conn.commit()
    
    # Store in Redis als JSON
    r.set('market_data', json.dumps(data))
    return data

    

@app.task
def fetch_grok_recommendations():
    """Holt täglich die Top-10 US-Aktien mit höchster 7-Tage-Gewinnwahrscheinlichkeit von Grok-API, speichert in Redis und PostgreSQL."""
    url = "https://grok.xai-api.com/v1/recommendations/top10"
    headers = {"Authorization": f"Bearer {GROK_API_KEY}"}
    try:
        response = requests.get(url, headers=headers, timeout=30)
        if response.status_code == 200:
            top10 = response.json()  # Erwartet: [{"ticker":..., "score":..., "reason":...}, ...]
            r.set('grok_top10', json.dumps(top10))
            # In DB speichern
            cur = conn.cursor()
            for rec in top10:
                cur.execute("""
                    INSERT INTO grok_recommendations (time, ticker, score, reason)
                    VALUES (NOW(), %s, %s, %s)
                """, (rec.get('ticker'), rec.get('score'), rec.get('reason')))
            conn.commit()
            logging.info("Grok Top-10 erfolgreich gespeichert")
            return top10
        else:
            logging.error(f"Grok API Fehler: {response.status_code} {response.text}")
            return None
    except Exception as e:
        logging.error(f"Grok API Exception: {str(e)}")
        return None
@app.task
def fetch_historical_data():
    """Hole historische Daten für AutoGluon Training"""
    cur = conn.cursor()
    
    for ticker in TICKERS:
        # Fetch historical data from Finnhub (last 30 days)
        end_time = int(datetime.now().timestamp())
        start_time = int((datetime.now() - timedelta(days=30)).timestamp())
        
        url = f'https://finnhub.io/api/v1/stock/candle?symbol={ticker}&resolution=15&from={start_time}&to={end_time}&token={FINNHUB_API_KEY}'
        response = requests.get(url)
        
        if response.status_code == 200:
            candles = response.json()
            if 's' in candles and candles['s'] == 'ok':
                for i in range(len(candles['t'])):
                    timestamp = datetime.fromtimestamp(candles['t'][i])
                    cur.execute("""
                        INSERT INTO market_data (time, ticker, open, high, low, close, volume)
                        VALUES (%s, %s, %s, %s, %s, %s, %s)
                        ON CONFLICT (time, ticker) DO NOTHING
                    """, (
                        timestamp,
                        ticker,
                        candles['o'][i],
                        candles['h'][i],
                        candles['l'][i],
                        candles['c'][i],
                        candles['v'][i]
                    ))
    
    conn.commit()
    logging.info("Historical data fetched successfully")
    return "Historical data updated"

@app.task
def train_model():
    """Trainiere AutoGluon Modell mit historischen Daten"""
    import pandas as pd
    
    cur = conn.cursor()
    
    # Hole historische Daten für alle Ticker
    cur.execute("""
        SELECT ticker, time, open, high, low, close, volume,
               LAG(close, 1) OVER (PARTITION BY ticker ORDER BY time) as prev_close,
               LAG(close, 5) OVER (PARTITION BY ticker ORDER BY time) as prev_close_5,
               LAG(close, 15) OVER (PARTITION BY ticker ORDER BY time) as prev_close_15
        FROM market_data 
        WHERE time >= NOW() - INTERVAL '7 days'
        ORDER BY ticker, time
    """)
    
    rows = cur.fetchall()
    
    if len(rows) < 100:
        logging.warning(f"Not enough data for training: {len(rows)} rows")
        return f"Insufficient data: {len(rows)} rows"
    
    # Erstelle DataFrame für AutoGluon
    df = pd.DataFrame(rows, columns=['ticker', 'time', 'open', 'high', 'low', 'close', 'volume', 'prev_close', 'prev_close_5', 'prev_close_15'])
    
    # Feature Engineering
    df['price_change'] = df['close'] - df['prev_close']
    df['price_change_5'] = df['close'] - df['prev_close_5']
    df['price_change_15'] = df['close'] - df['prev_close_15']
    df['volatility'] = (df['high'] - df['low']) / df['close']
    df['hour'] = pd.to_datetime(df['time']).dt.hour
    df['day_of_week'] = pd.to_datetime(df['time']).dt.dayofweek
    
    # Target: Preis in 1 Stunde (4 * 15-min intervals)
    df['target'] = df.groupby('ticker')['close'].shift(-4)
    
    # Entferne Zeilen ohne Target oder Features
    df = df.dropna()
    
    if len(df) < 50:
        logging.warning(f"Not enough clean data for training: {len(df)} rows")
        return f"Insufficient clean data: {len(df)} rows"
    
    # One-hot encode ticker
    df = pd.get_dummies(df, columns=['ticker'], prefix='ticker')
    
    # Wähle Features
    feature_columns = [col for col in df.columns if col not in ['time', 'target']]
    
    train_data = df[feature_columns + ['target']]
    
    try:
        # Trainiere AutoGluon Model
        predictor = TabularPredictor(
            label='target',
            path='./autogluon_model',
            eval_metric='mean_absolute_error'
        ).fit(train_data, time_limit=300)  # 5 Minuten
        
        r.set('model_trained', 'true')
        r.set('model_path', './autogluon_model')
        
        logging.info(f"Model trained successfully with {len(train_data)} samples")
        return f"Model trained with {len(train_data)} samples"
        
    except Exception as e:
        logging.error(f"Training failed: {str(e)}")
        return f"Training failed: {str(e)}"

@app.task
def trade_bot():
    # Get current prices and predictions
    # For each ticker, if predicted > current + 5%, buy
    # If predicted < current - 5%, sell
    headers = {
        'APCA-API-KEY-ID': ALPACA_API_KEY,
        'APCA-API-SECRET-KEY': ALPACA_SECRET
    }
    for ticker in TICKERS:
        # Get current price from Redis
        data = eval(r.get('market_data') or '{}')
        current_price = data.get(ticker, {}).get('price', 0)
        # Assume prediction from model
        # For simplicity, mock prediction
        predicted = current_price * 1.06  # Mock +6%
        if predicted > current_price * 1.05:
            # Buy
            order = {
                'symbol': ticker,
                'qty': 1,
                'side': 'buy',
                'type': 'market',
                'time_in_force': 'gtc'
            }
            response = requests.post('https://paper-api.alpaca.markets/v2/orders', json=order, headers=headers)
            logging.info(f'Buy order for {ticker}: {response.json()}')
        elif predicted < current_price * 0.95:
            # Sell
            order = {
                'symbol': ticker,
                'qty': 1,
                'side': 'sell',
                'type': 'market',
                'time_in_force': 'gtc'
            }
            response = requests.post('https://paper-api.alpaca.markets/v2/orders', json=order, headers=headers)
            logging.info(f'Sell order for {ticker}: {response.json()}')

@app.task
def daily_train():
    fetch_data.delay()
    train_model.delay()

# Schedule daily at 09:00 UTC
from celery.schedules import crontab
app.conf.beat_schedule = {
    'train-daily': {
        'task': 'worker.daily_train',
        'schedule': crontab(hour=9, minute=0),
    },
    'grok-top10-daily': {
        'task': 'worker.fetch_grok_recommendations',
        'schedule': crontab(hour=9, minute=5),
    },
    'portfolio-sync': {
        'task': 'worker.fetch_portfolio',
        'schedule': crontab(minute='*/5'),  # alle 5 Minuten
    },
    'tradebot-auto': {
        'task': 'worker.trade_bot',
        'schedule': crontab(minute='*/10'),  # alle 10 Minuten
    },
    'grok-deepersearch-daily': {
        'task': 'worker.fetch_grok_deepersearch',
        'schedule': crontab(hour=9, minute=10),
    },
}
