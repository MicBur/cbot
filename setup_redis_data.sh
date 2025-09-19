#!/bin/bash

# Setup script for Redis test data

echo "📊 Setting up Redis test data for QtTrade Frontend"
echo "=================================================="

# Configuration
REDIS_HOST=${REDIS_HOST:-127.0.0.1}
REDIS_PORT=${REDIS_PORT:-6380}
REDIS_CLI="redis-cli -h $REDIS_HOST -p $REDIS_PORT"

echo "🔧 Redis Configuration:"
echo "   Host: $REDIS_HOST"
echo "   Port: $REDIS_PORT"
echo ""

# Test Redis connection
echo "🔍 Testing Redis connection..."
if ! $REDIS_CLI ping &> /dev/null; then
    echo "❌ Cannot connect to Redis at $REDIS_HOST:$REDIS_PORT"
    echo ""
    echo "Please start Redis with:"
    echo "   redis-server --port $REDIS_PORT"
    echo ""
    echo "Or check if Redis is running on a different port:"
    echo "   redis-cli -p 6379 ping  # Default port"
    echo "   redis-cli -p 6380 ping  # Expected port"
    exit 1
fi

echo "✅ Redis connection successful"
echo ""

# Clear existing data (optional)
read -p "🗑️  Clear existing data? [y/N]: " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🧹 Clearing existing data..."
    $REDIS_CLI FLUSHDB
    echo "✅ Database cleared"
    echo ""
fi

echo "📊 Inserting market data..."

# Market Data
$REDIS_CLI HSET market:AAPL \
    symbol "AAPL" \
    price "150.25" \
    change "2.50" \
    changePercent "1.69" \
    volume "1250000" \
    high "152.00" \
    low "148.50"

$REDIS_CLI HSET market:GOOGL \
    symbol "GOOGL" \
    price "2750.50" \
    change "-15.25" \
    changePercent "-0.55" \
    volume "890000" \
    high "2780.00" \
    low "2740.00"

$REDIS_CLI HSET market:MSFT \
    symbol "MSFT" \
    price "305.75" \
    change "5.25" \
    changePercent "1.75" \
    volume "1100000" \
    high "307.00" \
    low "302.00"

$REDIS_CLI HSET market:TSLA \
    symbol "TSLA" \
    price "850.00" \
    change "-12.50" \
    changePercent "-1.45" \
    volume "2500000" \
    high "865.00" \
    low "845.00"

$REDIS_CLI HSET market:AMZN \
    symbol "AMZN" \
    price "3200.25" \
    change "45.75" \
    changePercent "1.45" \
    volume "750000" \
    high "3210.00" \
    low "3180.00"

echo "✅ Market data inserted (5 symbols)"

echo "💼 Inserting portfolio data..."

# Portfolio Data
$REDIS_CLI HSET portfolio:AAPL \
    ticker "AAPL" \
    qty "100" \
    avgPrice "145.50" \
    side "long"

$REDIS_CLI HSET portfolio:GOOGL \
    ticker "GOOGL" \
    qty "50" \
    avgPrice "2800.00" \
    side "long"

$REDIS_CLI HSET portfolio:MSFT \
    ticker "MSFT" \
    qty "75" \
    avgPrice "300.00" \
    side "long"

$REDIS_CLI HSET portfolio:TSLA \
    ticker "TSLA" \
    qty "25" \
    avgPrice "900.00" \
    side "short"

echo "✅ Portfolio data inserted (4 positions)"

echo "📋 Inserting orders data..."

# Orders Data
$REDIS_CLI HSET order:1 \
    id "1" \
    ticker "AAPL" \
    side "buy" \
    qty "10" \
    price "150.00" \
    status "filled" \
    timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

$REDIS_CLI HSET order:2 \
    id "2" \
    ticker "GOOGL" \
    side "sell" \
    qty "25" \
    price "2750.00" \
    status "open" \
    timestamp "$(date -u -d '1 hour ago' +"%Y-%m-%dT%H:%M:%SZ")"

$REDIS_CLI HSET order:3 \
    id "3" \
    ticker "MSFT" \
    side "buy" \
    qty "50" \
    price "305.00" \
    status "cancelled" \
    timestamp "$(date -u -d '2 hours ago' +"%Y-%m-%dT%H:%M:%SZ")"

$REDIS_CLI HSET order:4 \
    id "4" \
    ticker "TSLA" \
    side "sell" \
    qty "10" \
    price "860.00" \
    status "pending" \
    timestamp "$(date -u -d '30 minutes ago' +"%Y-%m-%dT%H:%M:%SZ")"

$REDIS_CLI HSET order:5 \
    id "5" \
    ticker "AMZN" \
    side "buy" \
    qty "5" \
    price "3180.00" \
    status "filled" \
    timestamp "$(date -u -d '15 minutes ago' +"%Y-%m-%dT%H:%M:%SZ")"

echo "✅ Orders data inserted (5 orders)"

echo "⚙️ Inserting system status..."

# System Status
$REDIS_CLI HSET system:status \
    postgres "true" \
    worker "true" \
    alpaca "true" \
    grok "false" \
    lastUpdate "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

echo "✅ System status inserted"

echo "🔔 Inserting notifications..."

# Notifications
$REDIS_CLI HSET notification:1 \
    id "1" \
    title "Order Filled" \
    message "AAPL buy order for 10 shares filled at \$150.00" \
    type "success" \
    timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    read "false"

$REDIS_CLI HSET notification:2 \
    id "2" \
    title "Price Alert" \
    message "TSLA dropped below \$860.00" \
    type "warning" \
    timestamp "$(date -u -d '5 minutes ago' +"%Y-%m-%dT%H:%M:%SZ")" \
    read "false"

$REDIS_CLI HSET notification:3 \
    id "3" \
    title "System Update" \
    message "Market data feed reconnected" \
    type "info" \
    timestamp "$(date -u -d '10 minutes ago' +"%Y-%m-%dT%H:%M:%SZ")" \
    read "true"

$REDIS_CLI HSET notification:4 \
    id "4" \
    title "Connection Error" \
    message "Alpaca API connection temporarily lost" \
    type "error" \
    timestamp "$(date -u -d '1 hour ago' +"%Y-%m-%dT%H:%M:%SZ")" \
    read "true"

echo "✅ Notifications inserted (4 notifications)"

echo ""
echo "📈 Data Summary:"
echo "=================="

# Show data summary
MARKET_COUNT=$($REDIS_CLI KEYS "market:*" | wc -l)
PORTFOLIO_COUNT=$($REDIS_CLI KEYS "portfolio:*" | wc -l)
ORDERS_COUNT=$($REDIS_CLI KEYS "order:*" | wc -l)
NOTIFICATIONS_COUNT=$($REDIS_CLI KEYS "notification:*" | wc -l)

echo "   Market symbols: $MARKET_COUNT"
echo "   Portfolio positions: $PORTFOLIO_COUNT"
echo "   Orders: $ORDERS_COUNT"
echo "   Notifications: $NOTIFICATIONS_COUNT"
echo ""

echo "🔍 Sample data verification:"
echo "   AAPL price: $($REDIS_CLI HGET market:AAPL price)"
echo "   Portfolio AAPL qty: $($REDIS_CLI HGET portfolio:AAPL qty)"
echo "   Latest order: $($REDIS_CLI HGET order:1 ticker) - $($REDIS_CLI HGET order:1 status)"
echo ""

echo "✅ Redis test data setup completed!"
echo ""
echo "🚀 You can now start the QtTrade Frontend:"
echo "   ./build_redis.sh"
echo "   cd build_redis"
echo "   ./QtTradeFrontend_Redis"
echo ""

# Optional: Create a data update script
cat > update_prices.sh << 'EOF'
#!/bin/bash
# Update market prices with random changes
REDIS_CLI="redis-cli -h 127.0.0.1 -p 6380"

symbols=("AAPL" "GOOGL" "MSFT" "TSLA" "AMZN")
for symbol in "${symbols[@]}"; do
    current_price=$($REDIS_CLI HGET "market:$symbol" price)
    if [ ! -z "$current_price" ]; then
        # Random price change between -2% and +2%
        change=$(echo "scale=2; ($RANDOM % 400 - 200) / 10000 * $current_price" | bc)
        new_price=$(echo "scale=2; $current_price + $change" | bc)
        change_percent=$(echo "scale=2; $change / $current_price * 100" | bc)
        
        $REDIS_CLI HSET "market:$symbol" price "$new_price"
        $REDIS_CLI HSET "market:$symbol" change "$change"
        $REDIS_CLI HSET "market:$symbol" changePercent "$change_percent"
        
        echo "Updated $symbol: \$${new_price} (${change_percent}%)"
    fi
done
EOF

chmod +x update_prices.sh
echo "📊 Created price update script: update_prices.sh"
echo "   Run it to simulate live price changes!"