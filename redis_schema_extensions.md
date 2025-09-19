# Redis Schema Erweiterungen für erweiterte Trading-Features

## Neue Redis Keys für 7-Tage Trading

### 1. Grok Tiefensuche Ergebnisse
```
Key: grok_deepersearch_enhanced
Format:
[
  {
    "ticker": "AAPL",
    "score": 0.92,
    "analysis": "Strong AI momentum",
    "sentiment": 0.85,
    "momentum_score": 0.78,
    "technical_score": 0.88,
    "fundamental_score": 0.91,
    "ml_confidence": 0.83,
    "reasons": [
      "New AI features in iOS",
      "Strong earnings beat",
      "Institutional buying"
    ],
    "risks": [
      "Valuation concerns",
      "China exposure"
    ],
    "target_price_7d": 245.50,
    "recommended_action": "BUY",
    "recommended_weight": 0.15
  },
  ...
]
```

### 2. 7-Tage ML Vorhersagen (5-Minuten Intervalle)
```
Key: predictions_7d_<SYMBOL>
Format:
[
  {
    "t": 1694606700,      // Unix timestamp
    "v": 235.10,          // Predicted price
    "conf": 0.87,         // Confidence (0-1)
    "vol": 125000,        // Predicted volume
    "action": "HOLD",     // BUY/SELL/HOLD signal
    "strength": 0.65      // Signal strength (0-1)
  },
  // 2016 data points (7 days * 24 hours * 12 intervals/hour)
]
```

### 3. Bot Trading Konfiguration
```
Key: bot_config
Format:
{
  "aggressiveness": 0.5,        // 0-1 scale (0=conservative, 1=aggressive)
  "max_position_size": 0.20,    // Max 20% of portfolio per position
  "max_holding_days": 7,        // Force sell after 7 days
  "min_confidence": 0.7,        // Minimum ML confidence for trades
  "stop_loss": 0.05,           // 5% stop loss
  "take_profit": 0.15,         // 15% take profit
  "trade_frequency": "5min",    // Check signals every 5 minutes
  "enabled": true,
  "allowed_symbols": ["AAPL", "NVDA", "MSFT", "TSLA", "AMZN"]
}
```

### 4. Trading Signale
```
Key: trading_signals_<SYMBOL>
Format:
[
  {
    "timestamp": 1694606700,
    "type": "BUY",              // BUY/SELL
    "price": 234.50,
    "confidence": 0.85,
    "reasons": [
      "ML prediction shows 8% upside",
      "Grok sentiment very positive",
      "Technical breakout detected"
    ],
    "predicted_exit": {
      "timestamp": 1695211500,  // Exit timestamp
      "price": 253.20,
      "return": 0.08
    }
  },
  ...
]
```

### 5. Chart Daten für 7 Tage (5-Min Candles)
```
Key: chart_data_7d_<SYMBOL>
Format:
[
  {
    "t": 1694606700,
    "o": 234.10,
    "h": 235.00,
    "l": 233.90,
    "c": 234.70,
    "vol": 15320
  },
  // 2016 candles (7 days of 5-min data)
]
```

### 6. Bot Aktionen Historie
```
Key: bot_actions
Format:
[
  {
    "timestamp": "2025-09-19T14:25:00Z",
    "action": "BUY",
    "symbol": "AAPL",
    "quantity": 100,
    "price": 234.50,
    "confidence": 0.85,
    "aggressiveness_level": 0.5,
    "predicted_sell_date": "2025-09-26T14:25:00Z",
    "predicted_return": 0.08,
    "reasons": ["ML signal", "Grok positive", "Technical breakout"],
    "order_id": "abc123"
  },
  ...
]
```

### 7. Performance Tracking
```
Key: ml_performance_7d
Format:
{
  "predictions_made": 150,
  "correct_direction": 112,
  "accuracy": 0.747,
  "avg_predicted_return": 0.045,
  "avg_actual_return": 0.038,
  "best_prediction": {
    "symbol": "NVDA",
    "predicted": 0.12,
    "actual": 0.14
  },
  "worst_prediction": {
    "symbol": "TSLA",
    "predicted": 0.08,
    "actual": -0.03
  }
}
```