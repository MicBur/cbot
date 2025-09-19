#!/usr/bin/env python3
"""
Trading Bot Service - Executes trades based on ML predictions
"""
import os
import time
import json
import redis
from datetime import datetime, timedelta
from alpaca_trade_api import REST
import logging
from typing import Dict, List, Optional

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class TradingBot:
    def __init__(self):
        self.redis_client = redis.Redis(
            host=os.getenv('REDIS_HOST', 'redis'),
            port=int(os.getenv('REDIS_PORT', 6379)),
            password=os.getenv('REDIS_PASSWORD') or None,
            decode_responses=True
        )
        
        # Alpaca API
        try:
            self.alpaca = REST(
                os.getenv('ALPACA_API_KEY'),
                os.getenv('ALPACA_SECRET_KEY'),
                base_url='https://paper-api.alpaca.markets' if os.getenv('BOT_MODE', 'paper') == 'paper' else 'https://api.alpaca.markets'
            )
            # Signal API availability for frontend status
            self.redis_client.set('api_status', 'valid')
        except Exception:
            self.redis_client.set('api_status', 'invalid')
        
        self.symbols = ['AAPL', 'NVDA', 'MSFT', 'TSLA', 'AMZN', 'META', 'GOOGL']
        self.positions = {}
        
    def get_bot_config(self) -> Dict:
        """Get bot configuration from Redis"""
        config_str = self.redis_client.get('bot_config')
        if config_str:
            return json.loads(config_str)
        
        # Default config
        return {
            'aggressiveness': 0.5,
            'max_position_size': 0.20,
            'max_holding_days': 7,
            'min_confidence': 0.7,
            'stop_loss': 0.05,
            'take_profit': 0.15,
            'trade_frequency': '5min',
            'enabled': True,
            'allowed_symbols': self.symbols
        }
    
    def update_positions(self):
        """Update current positions from Alpaca"""
        try:
            positions = self.alpaca.list_positions()
            self.positions = {p.symbol: p for p in positions}
            
            # Save to Redis
            positions_data = []
            for symbol, pos in self.positions.items():
                positions_data.append({
                    'symbol': symbol,
                    'qty': float(pos.qty),
                    'avg_entry_price': float(pos.avg_entry_price),
                    'market_value': float(pos.market_value),
                    'unrealized_pl': float(pos.unrealized_pl),
                    'entry_time': pos.exchange
                })
            
            self.redis_client.set('bot_positions', json.dumps(positions_data))
            
        except Exception as e:
            logger.error(f"Error updating positions: {str(e)}")
    
    def get_account_info(self) -> Dict:
        """Get account information"""
        try:
            account = self.alpaca.get_account()
            return {
                'buying_power': float(account.buying_power),
                'portfolio_value': float(account.portfolio_value),
                'cash': float(account.cash),
                'equity': float(account.equity)
            }
        except Exception as e:
            logger.error(f"Error getting account info: {str(e)}")
            return {}
    
    def get_trading_signals(self, symbol: str) -> List[Dict]:
        """Get trading signals from Redis"""
        key = f'trading_signals_{symbol}'
        signals_str = self.redis_client.get(key)
        if signals_str:
            return json.loads(signals_str)
        return []
    
    def should_buy(self, symbol: str, signal: Dict, config: Dict) -> bool:
        """Determine if we should buy based on signal and config"""
        # Check if bot is enabled
        if not config['enabled']:
            return False
        
        # Check if symbol is allowed
        if symbol not in config['allowed_symbols']:
            return False
        
        # Check confidence threshold
        if signal.get('conf', 0) < config['min_confidence']:
            return False
        
        # Check if we already have a position
        if symbol in self.positions:
            current_position = self.positions[symbol]
            # Check if position is too large
            account = self.get_account_info()
            position_value = float(current_position.market_value)
            if position_value > account['portfolio_value'] * config['max_position_size']:
                return False
        
        # Check signal strength vs aggressiveness
        required_strength = 1.0 - config['aggressiveness']
        if signal.get('strength', 0) < required_strength:
            return False
        
        return True
    
    def should_sell(self, symbol: str, signal: Dict, config: Dict) -> bool:
        """Determine if we should sell based on signal and config"""
        if symbol not in self.positions:
            return False
        
        position = self.positions[symbol]
        
        # Check holding period
        # Note: In real implementation, store entry time properly
        # For now, we'll use a simple check
        
        # Check stop loss
        current_pl_pct = float(position.unrealized_plpct)
        if current_pl_pct <= -config['stop_loss']:
            logger.info(f"Stop loss triggered for {symbol}")
            return True
        
        # Check take profit
        if current_pl_pct >= config['take_profit']:
            logger.info(f"Take profit triggered for {symbol}")
            return True
        
        # Check sell signal
        if signal.get('action') == 'SELL' and signal.get('conf', 0) >= config['min_confidence']:
            return True
        
        return False
    
    def calculate_position_size(self, symbol: str, config: Dict) -> int:
        """Calculate position size based on config and account"""
        try:
            account = self.get_account_info()
            max_position_value = account['portfolio_value'] * config['max_position_size']
            
            # Get current price
            quote = self.alpaca.get_latest_quote(symbol)
            current_price = float(quote.ask_price)
            
            # Calculate shares
            shares = int(max_position_value / current_price)
            
            # Adjust based on aggressiveness
            shares = int(shares * config['aggressiveness'])
            
            return max(1, shares)
            
        except Exception as e:
            logger.error(f"Error calculating position size: {str(e)}")
            return 1
    
    def execute_buy(self, symbol: str, signal: Dict, config: Dict):
        """Execute buy order"""
        try:
            qty = self.calculate_position_size(symbol, config)
            
            order = self.alpaca.submit_order(
                symbol=symbol,
                qty=qty,
                side='buy',
                type='market',
                time_in_force='day'
            )
            
            logger.info(f"Buy order submitted for {symbol}: {qty} shares")
            
            # Log to Redis
            self.log_action({
                'timestamp': datetime.now().isoformat(),
                'action': 'BUY',
                'symbol': symbol,
                'quantity': qty,
                'confidence': signal.get('conf', 0),
                'aggressiveness_level': config['aggressiveness'],
                'predicted_return': signal.get('strength', 0),
                'reasons': [f"ML confidence: {signal.get('conf', 0)}", 
                          f"Signal strength: {signal.get('strength', 0)}"],
                'order_id': order.id
            })
            
        except Exception as e:
            logger.error(f"Error executing buy order: {str(e)}")
    
    def execute_sell(self, symbol: str, signal: Dict, config: Dict):
        """Execute sell order"""
        try:
            if symbol not in self.positions:
                return
            
            position = self.positions[symbol]
            qty = abs(int(position.qty))
            
            order = self.alpaca.submit_order(
                symbol=symbol,
                qty=qty,
                side='sell',
                type='market',
                time_in_force='day'
            )
            
            logger.info(f"Sell order submitted for {symbol}: {qty} shares")
            
            # Log to Redis
            self.log_action({
                'timestamp': datetime.now().isoformat(),
                'action': 'SELL',
                'symbol': symbol,
                'quantity': qty,
                'confidence': signal.get('conf', 0),
                'aggressiveness_level': config['aggressiveness'],
                'realized_pl': float(position.unrealized_pl),
                'reasons': [f"ML confidence: {signal.get('conf', 0)}",
                          f"P/L: {float(position.unrealized_plpct)*100:.2f}%"],
                'order_id': order.id
            })
            
        except Exception as e:
            logger.error(f"Error executing sell order: {str(e)}")
    
    def check_forced_sells(self, config: Dict):
        """Check for positions that need to be force sold (7-day limit)"""
        # In a real implementation, track entry times properly
        # For now, this is a placeholder
        pass
    
    def log_action(self, action: Dict):
        """Log bot action to Redis"""
        key = 'bot_actions'
        actions_str = self.redis_client.get(key)
        actions = json.loads(actions_str) if actions_str else []
        
        # Add new action
        actions.append(action)
        
        # Keep last 100 actions
        actions = actions[-100:]
        
        self.redis_client.set(key, json.dumps(actions))
    
    def update_performance_metrics(self):
        """Update ML performance metrics"""
        # Track prediction accuracy
        # This would compare historical predictions with actual results
        pass
    
    def run(self):
        """Main bot loop"""
        logger.info("Trading Bot started")
        
        while True:
            try:
                # Get bot config
                config = self.get_bot_config()
                
                if not config['enabled']:
                    logger.info("Bot is disabled")
                    time.sleep(300)
                    continue
                
                # Update positions
                self.update_positions()
                
                # Check each symbol
                for symbol in config['allowed_symbols']:
                    # Get trading signals
                    signals = self.get_trading_signals(symbol)
                    
                    if not signals:
                        continue
                    
                    # Get most recent signal
                    latest_signal = signals[0]
                    
                    # Check if signal is recent (within 5 minutes)
                    signal_age = time.time() - latest_signal.get('t', 0)
                    if signal_age > 300:  # 5 minutes
                        continue
                    
                    # Decide action
                    if latest_signal.get('action') == 'BUY':
                        if self.should_buy(symbol, latest_signal, config):
                            self.execute_buy(symbol, latest_signal, config)
                    
                    elif latest_signal.get('action') == 'SELL':
                        if self.should_sell(symbol, latest_signal, config):
                            self.execute_sell(symbol, latest_signal, config)
                
                # Check for forced sells (7-day limit)
                self.check_forced_sells(config)
                
                # Update performance metrics
                self.update_performance_metrics()
                
                # Sleep based on trade frequency
                sleep_time = 300  # Default 5 minutes
                if config['trade_frequency'] == '1min':
                    sleep_time = 60
                elif config['trade_frequency'] == '15min':
                    sleep_time = 900
                
                time.sleep(sleep_time)
                
            except Exception as e:
                logger.error(f"Error in bot loop: {str(e)}")
                time.sleep(60)

if __name__ == '__main__':
    bot = TradingBot()
    bot.run()