#!/bin/bash

# Build script for QtTrade Frontend - Direct Redis Integration

echo "🚀 QtTrade Frontend Redis Build Script"
echo "========================================"
echo ""

# Check if we're in the right directory
if [ ! -f "CMakeLists_Redis.txt" ]; then
    echo "❌ Error: CMakeLists_Redis.txt not found. Are you in the project root?"
    exit 1
fi

# Check for hiredis
if [ ! -d "hiredis-1.3.0" ]; then
    echo "⚠️  Warning: hiredis-1.3.0/ not found in project root"
    echo "   Trying to use system hiredis..."
    
    # Check for system hiredis
    if ! pkg-config --exists hiredis 2>/dev/null && ! ldconfig -p | grep -q libhiredis; then
        echo "❌ Error: hiredis not found!"
        echo ""
        echo "Please install hiredis:"
        echo "  Ubuntu/Debian: sudo apt install libhiredis-dev"
        echo "  CentOS/RHEL:   sudo yum install hiredis-devel"
        echo "  Arch:          sudo pacman -S hiredis"
        echo "  macOS:         brew install hiredis"
        echo ""
        echo "Or place hiredis-1.3.0/ directory in project root."
        exit 1
    else
        echo "✅ Found system hiredis"
    fi
else
    echo "✅ Found bundled hiredis: hiredis-1.3.0/"
fi

# Create build directory
BUILD_DIR="build_redis"
echo "📁 Creating build directory: $BUILD_DIR"
mkdir -p $BUILD_DIR
cd $BUILD_DIR

# Configuration options
CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE:-Release}
QT_VERSION=${QT_VERSION:-6}

echo "🔧 Build Configuration:"
echo "   Build Type: $CMAKE_BUILD_TYPE"
echo "   Qt Version: $QT_VERSION"
echo ""

# Configure with CMake
echo "⚙️  Configuring with CMake..."
cmake -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE \
      -DQT_VERSION_MAJOR=$QT_VERSION \
      -f ../CMakeLists_Redis.txt \
      ..

if [ $? -ne 0 ]; then
    echo "❌ Error: CMake configuration failed"
    echo ""
    echo "Common issues:"
    echo "1. Qt not found - install Qt development packages"
    echo "2. hiredis not found - see instructions above"
    echo "3. Wrong Qt version - try QT_VERSION=5 or QT_VERSION=6"
    exit 1
fi

# Build the project
echo ""
echo "🔨 Building project..."
make -j$(nproc)

if [ $? -ne 0 ]; then
    echo "❌ Error: Build failed"
    echo ""
    echo "Check the error messages above for details."
    exit 1
fi

echo ""
echo "✅ Build completed successfully!"
echo ""
echo "📋 Build Summary:"
echo "   Executable: $BUILD_DIR/QtTradeFrontend_Redis"
echo "   Build Type: $CMAKE_BUILD_TYPE"
echo "   Qt Version: $(qmake -query QT_VERSION 2>/dev/null || echo "Unknown")"
echo ""

# Optional: Run QML linting if available
if command -v qmllint &> /dev/null; then
    echo "🔍 Running QML linter..."
    make qml_lint
    echo ""
else
    echo "⚠️  qmllint not found - skipping QML linting"
    echo ""
fi

# Test Redis connection
echo "🔍 Testing Redis connection..."
if command -v redis-cli &> /dev/null; then
    if redis-cli -p 6380 ping &> /dev/null; then
        echo "✅ Redis is running on port 6380"
    elif redis-cli -p 6379 ping &> /dev/null; then
        echo "⚠️  Redis is running on default port 6379 (expected 6380)"
        echo "   Start Redis with: redis-server --port 6380"
    else
        echo "❌ Redis not running. Start with:"
        echo "   redis-server --port 6380"
    fi
else
    echo "⚠️  redis-cli not found - cannot test Redis connection"
fi

echo ""
echo "🚀 Ready to run!"
echo ""
echo "To start the application:"
echo "  cd $BUILD_DIR"
echo "  ./QtTradeFrontend_Redis"
echo ""
echo "Make sure Redis is running:"
echo "  redis-server --port 6380"
echo ""

# Optional: Create desktop entry on Linux
if [ "$1" == "--install-desktop" ] && [ "$(uname)" == "Linux" ]; then
    echo "🖥️  Creating desktop entry..."
    DESKTOP_FILE="$HOME/.local/share/applications/qttrade-redis.desktop"
    cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=QtTrade Frontend Redis
Comment=Direct Redis Trading Frontend
Exec=$(pwd)/QtTradeFrontend_Redis
Icon=applications-office
Terminal=false
Categories=Office;Finance;
EOF
    echo "✅ Desktop entry created: $DESKTOP_FILE"
    echo ""
fi

echo "🎯 Build script completed successfully!"