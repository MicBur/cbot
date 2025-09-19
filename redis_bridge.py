#!/usr/bin/env python3
"""
Redis Bridge Server für QML Frontend
Stellt WebSocket und HTTP API für Redis-Daten bereit
"""

import asyncio
import websockets
import json
import redis
import threading
import time
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

class RedisBridge:
    def __init__(self, redis_host='127.0.0.1', redis_port=6380, redis_password=''):
        self.redis_client = redis.Redis(
            host=redis_host, 
            port=redis_port, 
            password=redis_password,
            decode_responses=True
        )
        self.websocket_clients = set()
        
    def test_redis_connection(self):
        """Test Redis connection"""
        try:
            self.redis_client.ping()
            print(f"✅ Redis connected: {self.redis_client.connection_pool.connection_kwargs}")
            return True
        except Exception as e:
            print(f"❌ Redis connection failed: {e}")
            return False
    
    async def websocket_handler(self, websocket, path):
        """Handle WebSocket connections from QML frontend"""
        print(f"📡 WebSocket client connected: {websocket.remote_address}")
        self.websocket_clients.add(websocket)
        
        try:
            async for message in websocket:
                try:
                    data = json.loads(message)
                    await self.handle_websocket_message(websocket, data)
                except json.JSONDecodeError:
                    await websocket.send(json.dumps({
                        "error": "Invalid JSON"
                    }))
        except websockets.exceptions.ConnectionClosed:
            print(f"📡 WebSocket client disconnected: {websocket.remote_address}")
        finally:
            self.websocket_clients.discard(websocket)
    
    async def handle_websocket_message(self, websocket, data):
        """Process WebSocket messages"""
        action = data.get('action')
        
        if action == 'subscribe':
            channels = data.get('channels', [])
            print(f"📡 Client subscribed to: {channels}")
            
            # Send initial data for each channel
            for channel in channels:
                initial_data = self.get_redis_data(channel)
                if initial_data:
                    await websocket.send(json.dumps({
                        "channel": channel,
                        "payload": initial_data
                    }))
        
        elif action == 'get_data':
            channel = data.get('channel')
            redis_data = self.get_redis_data(channel)
            await websocket.send(json.dumps({
                "channel": channel,
                "payload": redis_data
            }))
    
    def get_redis_data(self, channel):
        """Get data from Redis for specific channel"""
        try:
            if channel == 'market':
                # Get market data from Redis
                market_keys = self.redis_client.keys('market:*')
                market_data = []
                for key in market_keys[:10]:  # Limit to 10 items
                    data = self.redis_client.hgetall(key)
                    if data:
                        market_data.append({
                            'symbol': data.get('symbol', ''),
                            'price': float(data.get('price', 0)),
                            'change': float(data.get('change', 0)),
                            'changePercent': float(data.get('changePercent', 0)),
                            'volume': int(data.get('volume', 0)),
                            'high': float(data.get('high', 0)),
                            'low': float(data.get('low', 0))
                        })
                return market_data
                
            elif channel == 'portfolio':
                # Get portfolio data from Redis
                portfolio_keys = self.redis_client.keys('portfolio:*')
                portfolio_data = []
                for key in portfolio_keys:
                    data = self.redis_client.hgetall(key)
                    if data:
                        portfolio_data.append({
                            'ticker': data.get('ticker', ''),
                            'qty': float(data.get('qty', 0)),
                            'avgPrice': float(data.get('avgPrice', 0)),
                            'side': data.get('side', 'long')
                        })
                return portfolio_data
                
            elif channel == 'orders':
                # Get orders data from Redis
                orders_keys = self.redis_client.keys('order:*')
                orders_data = []
                for key in orders_keys:
                    data = self.redis_client.hgetall(key)
                    if data:
                        orders_data.append({
                            'id': data.get('id', ''),
                            'ticker': data.get('ticker', ''),
                            'side': data.get('side', ''),
                            'qty': float(data.get('qty', 0)),
                            'price': float(data.get('price', 0)),
                            'status': data.get('status', ''),
                            'timestamp': data.get('timestamp', '')
                        })
                return orders_data
                
            elif channel == 'status':
                # Get system status from Redis
                status_data = self.redis_client.hgetall('system:status')
                return {
                    'postgresConnected': status_data.get('postgres', 'false') == 'true',
                    'workerRunning': status_data.get('worker', 'false') == 'true',
                    'alpacaApiActive': status_data.get('alpaca', 'false') == 'true',
                    'grokApiActive': status_data.get('grok', 'false') == 'true'
                }
                
        except Exception as e:
            print(f"❌ Redis error for channel {channel}: {e}")
            return None
        
        return None
    
    async def broadcast_updates(self):
        """Broadcast Redis updates to all WebSocket clients"""
        while True:
            if self.websocket_clients:
                try:
                    # Check for updates in Redis and broadcast
                    for channel in ['market', 'portfolio', 'orders', 'status']:
                        data = self.get_redis_data(channel)
                        if data:
                            message = json.dumps({
                                "channel": channel,
                                "payload": data
                            })
                            
                            # Send to all connected clients
                            disconnected = set()
                            for client in self.websocket_clients:
                                try:
                                    await client.send(message)
                                except:
                                    disconnected.add(client)
                            
                            # Remove disconnected clients
                            self.websocket_clients -= disconnected
                
                except Exception as e:
                    print(f"❌ Broadcast error: {e}")
            
            await asyncio.sleep(1)  # Update every second

class HTTPHandler(BaseHTTPRequestHandler):
    def __init__(self, redis_bridge, *args, **kwargs):
        self.redis_bridge = redis_bridge
        super().__init__(*args, **kwargs)
    
    def do_GET(self):
        """Handle HTTP GET requests"""
        parsed = urlparse(self.path)
        path = parsed.path
        
        if path.startswith('/api/'):
            channel = path.split('/')[-1]
            data = self.redis_bridge.get_redis_data(channel)
            
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            
            if data:
                self.wfile.write(json.dumps(data).encode())
            else:
                self.wfile.write(json.dumps([]).encode())
        else:
            self.send_response(404)
            self.end_headers()

def run_http_server(redis_bridge, port=8080):
    """Run HTTP server in separate thread"""
    handler = lambda *args, **kwargs: HTTPHandler(redis_bridge, *args, **kwargs)
    httpd = HTTPServer(('0.0.0.0', port), handler)
    print(f"🌐 HTTP API server running on port {port}")
    httpd.serve_forever()

async def main():
    # Initialize Redis Bridge
    bridge = RedisBridge()
    
    # Test Redis connection
    if not bridge.test_redis_connection():
        print("❌ Cannot connect to Redis. Please check your Redis server.")
        return
    
    # Start HTTP server in background thread
    http_thread = threading.Thread(target=run_http_server, args=(bridge,))
    http_thread.daemon = True
    http_thread.start()
    
    # Start WebSocket server
    print("📡 Starting WebSocket server on port 7380...")
    websocket_server = websockets.serve(bridge.websocket_handler, "0.0.0.0", 7380)
    
    # Start broadcast task
    broadcast_task = asyncio.create_task(bridge.broadcast_updates())
    
    # Run both servers
    await asyncio.gather(
        websocket_server,
        broadcast_task
    )

if __name__ == "__main__":
    print("🚀 Redis Bridge Server for QML Frontend")
    print("=" * 50)
    asyncio.run(main())