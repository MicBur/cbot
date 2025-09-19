#!/bin/bash

# Build script for QtTrade Frontend - Pure QML Version

echo "=== QtTrade Frontend QML Build Script ==="
echo ""

# Check if we're in the right directory
if [ ! -f "CMakeLists_QML.txt" ]; then
    echo "Error: CMakeLists_QML.txt not found. Are you in the project root?"
    exit 1
fi

# Create build directory
BUILD_DIR="build_qml"
echo "Creating build directory: $BUILD_DIR"
mkdir -p $BUILD_DIR
cd $BUILD_DIR

# Configuration options
CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE:-Release}
QT_VERSION=${QT_VERSION:-6}

echo "Build Type: $CMAKE_BUILD_TYPE"
echo "Qt Version: $QT_VERSION"
echo ""

# Configure with CMake
echo "Configuring with CMake..."
cmake -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE \
      -DQT_VERSION_MAJOR=$QT_VERSION \
      -f ../CMakeLists_QML.txt \
      ..

if [ $? -ne 0 ]; then
    echo "Error: CMake configuration failed"
    exit 1
fi

# Build the project
echo ""
echo "Building project..."
make -j$(nproc)

if [ $? -ne 0 ]; then
    echo "Error: Build failed"
    exit 1
fi

echo ""
echo "=== Build completed successfully! ==="
echo ""
echo "Executable: $BUILD_DIR/QtTradeFrontend_QML"
echo ""

# Optional: Run QML linting if available
if command -v qmllint &> /dev/null; then
    echo "Running QML linter..."
    make qml_lint
else
    echo "qmllint not found - skipping QML linting"
fi

echo ""
echo "To run the application:"
echo "  cd $BUILD_DIR"
echo "  ./QtTradeFrontend_QML"
echo ""

# Optional: Create desktop entry on Linux
if [ "$1" == "--install-desktop" ] && [ "$(uname)" == "Linux" ]; then
    echo "Creating desktop entry..."
    DESKTOP_FILE="$HOME/.local/share/applications/qttrade-qml.desktop"
    cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=QtTrade Frontend QML
Comment=Pure QML Trading Frontend
Exec=$(pwd)/QtTradeFrontend_QML
Icon=applications-office
Terminal=false
Categories=Office;Finance;
EOF
    echo "Desktop entry created: $DESKTOP_FILE"
fi

echo "Build script completed!"