#!/usr/bin/env python3
"""
ML Worker Service for 7-day predictions with 5-minute intervals
"""
import os
import time
import json
import redis
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from autogluon.tabular import TabularPredictor
import logging
from typing import Dict, List, Tuple

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class MLWorker:
    def __init__(self):
        self.redis_client = redis.Redis(
            host=os.getenv('REDIS_HOST', 'redis'),
            port=int(os.getenv('REDIS_PORT', 6379)),
            password=os.getenv('REDIS_PASSWORD') or None,
            decode_responses=True
        )
        self.model_path = '/app/ml_models'
        self.symbols = ['AAPL', 'NVDA', 'MSFT', 'TSLA', 'AMZN', 'META', 'GOOGL']
        
    def build_features(self, df: pd.DataFrame) -> pd.DataFrame:
        """Enhanced feature engineering for 7-day predictions"""
        df = df.sort_values(['symbol', 'timestamp'])
        
        # Price features
        df['returns_5m'] = df.groupby('symbol')['close'].pct_change()
        df['returns_15m'] = df.groupby('symbol')['close'].pct_change(3)
        df['returns_1h'] = df.groupby('symbol')['close'].pct_change(12)
        df['returns_1d'] = df.groupby('symbol')['close'].pct_change(288)
        
        # Moving averages
        df['sma_1h'] = df.groupby('symbol')['close'].rolling(12).mean().reset_index(0, drop=True)
        df['sma_4h'] = df.groupby('symbol')['close'].rolling(48).mean().reset_index(0, drop=True)
        df['sma_1d'] = df.groupby('symbol')['close'].rolling(288).mean().reset_index(0, drop=True)
        
        # Exponential moving averages
        df['ema_fast'] = df.groupby('symbol')['close'].ewm(span=12).mean().reset_index(0, drop=True)
        df['ema_slow'] = df.groupby('symbol')['close'].ewm(span=48).mean().reset_index(0, drop=True)
        df['ema_ratio'] = df['ema_fast'] / df['ema_slow']
        
        # Volatility
        df['volatility_1h'] = df.groupby('symbol')['returns_5m'].rolling(12).std().reset_index(0, drop=True)
        df['volatility_1d'] = df.groupby('symbol')['returns_5m'].rolling(288).std().reset_index(0, drop=True)
        
        # Price position
        df['price_position'] = (df['close'] - df['sma_1d']) / df['sma_1d']
        
        # Volume features
        df['volume_ratio'] = df['volume'] / df.groupby('symbol')['volume'].rolling(288).mean().reset_index(0, drop=True)
        
        # Technical indicators
        df['rsi'] = self.calculate_rsi(df)
        df['macd'], df['macd_signal'] = self.calculate_macd(df)
        
        # Time features
        df['hour'] = pd.to_datetime(df['timestamp']).dt.hour
        df['day_of_week'] = pd.to_datetime(df['timestamp']).dt.dayofweek
        df['is_market_hours'] = ((df['hour'] >= 9) & (df['hour'] < 16)).astype(int)
        
        # Lag features
        for lag in [1, 3, 6, 12, 24]:
            df[f'close_lag_{lag}'] = df.groupby('symbol')['close'].shift(lag)
            df[f'volume_lag_{lag}'] = df.groupby('symbol')['volume'].shift(lag)
        
        # Drop NaN values
        df = df.dropna()
        
        return df
    
    def calculate_rsi(self, df: pd.DataFrame, period: int = 14) -> pd.Series:
        """Calculate RSI indicator"""
        delta = df.groupby('symbol')['close'].diff()
        gain = (delta.where(delta > 0, 0)).rolling(window=period).mean()
        loss = (-delta.where(delta < 0, 0)).rolling(window=period).mean()
        rs = gain / loss
        rsi = 100 - (100 / (1 + rs))
        return rsi
    
    def calculate_macd(self, df: pd.DataFrame) -> Tuple[pd.Series, pd.Series]:
        """Calculate MACD indicator"""
        exp1 = df.groupby('symbol')['close'].ewm(span=12).mean()
        exp2 = df.groupby('symbol')['close'].ewm(span=26).mean()
        macd = exp1 - exp2
        signal = macd.ewm(span=9).mean()
        return macd, signal
    
    def train_model(self, symbol: str) -> TabularPredictor:
        """Train AutoGluon model for 7-day predictions"""
        logger.info(f"Training model for {symbol}")
        
        # Load historical data
        df = self.load_historical_data(symbol)
        
        # Build features
        df_features = self.build_features(df)
        
        # Create targets for different horizons (5min intervals for 7 days)
        horizons = [12, 48, 144, 288, 576, 1152, 2016]  # 1h, 4h, 12h, 1d, 2d, 4d, 7d
        
        for horizon in horizons:
            df_features[f'target_{horizon}'] = df_features.groupby('symbol')['close'].shift(-horizon)
        
        # Drop rows with NaN targets
        df_train = df_features.dropna()
        
        # Split features and target
        feature_cols = [col for col in df_train.columns if not col.startswith('target_')]
        
        # Train model for 7-day prediction
        predictor = TabularPredictor(
            label='target_2016',
            path=f'{self.model_path}/{symbol}_7d',
            eval_metric='rmse'
        )
        
        predictor.fit(
            df_train[feature_cols + ['target_2016']],
            presets='best_quality',
            time_limit=600
        )
        
        return predictor
    
    def generate_predictions(self, symbol: str) -> List[Dict]:
        """Generate 7-day predictions with 5-minute intervals"""
        logger.info(f"Generating predictions for {symbol}")
        
        try:
            # Load model
            predictor = TabularPredictor.load(f'{self.model_path}/{symbol}_7d')
            
            # Get latest data
            df_latest = self.load_latest_data(symbol)
            df_features = self.build_features(df_latest)
            
            # Generate predictions for next 7 days (2016 5-min intervals)
            predictions = []
            current_features = df_features.iloc[-1:].copy()
            
            base_timestamp = int(time.time())
            
            for i in range(2016):  # 7 days * 24 hours * 12 intervals/hour
                # Predict next value
                pred_value = predictor.predict(current_features)[0]
                
                # Calculate confidence based on model's feature importance
                confidence = self.calculate_confidence(predictor, current_features)
                
                # Determine trading action
                action, strength = self.determine_action(
                    current_price=current_features['close'].iloc[0],
                    predicted_price=pred_value,
                    confidence=confidence
                )
                
                predictions.append({
                    't': base_timestamp + (i * 300),  # 5 minutes = 300 seconds
                    'v': float(pred_value),
                    'conf': float(confidence),
                    'action': action,
                    'strength': float(strength)
                })
                
                # Update features for next prediction
                current_features['close'] = pred_value
                current_features = self.update_features_for_next_step(current_features)
            
            return predictions
            
        except Exception as e:
            logger.error(f"Error generating predictions for {symbol}: {str(e)}")
            return []
    
    def calculate_confidence(self, predictor: TabularPredictor, features: pd.DataFrame) -> float:
        """Calculate prediction confidence"""
        # Simple confidence based on feature importance and data quality
        feature_importance = predictor.feature_importance(features)
        
        # Base confidence
        confidence = 0.7
        
        # Adjust based on volatility
        if 'volatility_1d' in features.columns:
            vol = features['volatility_1d'].iloc[0]
            if vol < 0.02:  # Low volatility
                confidence += 0.1
            elif vol > 0.05:  # High volatility
                confidence -= 0.1
        
        # Adjust based on volume
        if 'volume_ratio' in features.columns:
            vol_ratio = features['volume_ratio'].iloc[0]
            if vol_ratio > 1.5:  # High volume
                confidence += 0.05
        
        return np.clip(confidence, 0.1, 0.95)
    
    def determine_action(self, current_price: float, predicted_price: float, 
                        confidence: float) -> Tuple[str, float]:
        """Determine trading action based on prediction"""
        price_change = (predicted_price - current_price) / current_price
        
        # Get bot aggressiveness
        bot_config = self.redis_client.get('bot_config')
        aggressiveness = 0.5
        if bot_config:
            config = json.loads(bot_config)
            aggressiveness = config.get('aggressiveness', 0.5)
        
        # Adjust thresholds based on aggressiveness
        buy_threshold = 0.02 * (2 - aggressiveness)  # 1-3% depending on aggressiveness
        sell_threshold = -0.02 * (2 - aggressiveness)
        
        # Factor in confidence
        adjusted_change = price_change * confidence
        
        if adjusted_change > buy_threshold:
            strength = min(1.0, adjusted_change / 0.1)  # Max strength at 10% gain
            return "BUY", strength
        elif adjusted_change < sell_threshold:
            strength = min(1.0, abs(adjusted_change) / 0.1)
            return "SELL", strength
        else:
            return "HOLD", 0.0
    
    def update_features_for_next_step(self, features: pd.DataFrame) -> pd.DataFrame:
        """Update features for next prediction step"""
        # Shift lag features
        for col in features.columns:
            if 'lag_' in col:
                lag_num = int(col.split('_')[-1])
                if lag_num > 1:
                    features[col] = features[col.replace(f'lag_{lag_num}', f'lag_{lag_num-1}')]
        
        # Update time features
        features['hour'] = (features['hour'] + 5/60) % 24
        
        return features
    
    def load_historical_data(self, symbol: str) -> pd.DataFrame:
        """Load historical data from Redis"""
        # Implementation depends on your data storage
        # This is a placeholder
        key = f'chart_data_7d_{symbol}'
        data = self.redis_client.get(key)
        if data:
            candles = json.loads(data)
            df = pd.DataFrame(candles)
            df['symbol'] = symbol
            df['timestamp'] = pd.to_datetime(df['t'], unit='s')
            return df
        return pd.DataFrame()
    
    def load_latest_data(self, symbol: str) -> pd.DataFrame:
        """Load latest data for predictions"""
        # Similar to load_historical_data but gets most recent data
        return self.load_historical_data(symbol).tail(2016)
    
    def save_predictions(self, symbol: str, predictions: List[Dict]):
        """Save predictions to Redis"""
        key = f'predictions_7d_{symbol}'
        self.redis_client.set(key, json.dumps(predictions))
        self.redis_client.expire(key, 7200)  # 2 hour expiry
        
        # Also save trading signals
        signals = [p for p in predictions if p['action'] in ['BUY', 'SELL']]
        if signals:
            signals_key = f'trading_signals_{symbol}'
            self.redis_client.set(signals_key, json.dumps(signals[:20]))  # Save top 20 signals
    
    def run(self):
        """Main worker loop"""
        logger.info("ML Worker started")
        
        while True:
            try:
                # Check if training is triggered
                ml_trigger = self.redis_client.get('manual_trigger_ml')
                if ml_trigger == 'true':
                    self.redis_client.set('manual_trigger_ml', 'false')
                    
                    # Update status
                    self.redis_client.set('ml_status', json.dumps({
                        'training_active': True,
                        'last_training': datetime.now().isoformat(),
                        'training_progress': 0.0
                    }))
                    
                    # Train models for all symbols
                    for i, symbol in enumerate(self.symbols):
                        progress = (i / len(self.symbols))
                        self.redis_client.set('ml_status', json.dumps({
                            'training_active': True,
                            'last_training': datetime.now().isoformat(),
                            'training_progress': progress,
                            'current_symbol': symbol
                        }))
                        
                        # Train model
                        predictor = self.train_model(symbol)
                        
                        # Generate predictions
                        predictions = self.generate_predictions(symbol)
                        
                        # Save predictions
                        self.save_predictions(symbol, predictions)
                    
                    # Update final status
                    self.redis_client.set('ml_status', json.dumps({
                        'training_active': False,
                        'last_training': datetime.now().isoformat(),
                        'training_progress': 1.0,
                        'next_scheduled': (datetime.now() + timedelta(hours=24)).isoformat()
                    }))
                
                # Generate predictions every hour
                current_hour = datetime.now().hour
                if current_hour % 1 == 0:  # Every hour
                    for symbol in self.symbols:
                        predictions = self.generate_predictions(symbol)
                        self.save_predictions(symbol, predictions)
                
                # Sleep for 5 minutes
                time.sleep(300)
                
            except Exception as e:
                logger.error(f"Error in ML worker: {str(e)}")
                time.sleep(60)

if __name__ == '__main__':
    worker = MLWorker()
    worker.run()