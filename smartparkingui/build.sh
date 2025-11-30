#!/bin/bash

# SmartParkingUI Build Script for Linux

set -e

echo "=== SmartParkingUI Build Script ==="

# Check if Qt6 is installed
if ! command -v qmake6 &> /dev/null && ! command -v qmake &> /dev/null; then
    echo "Error: Qt6 not found. Please install Qt6 first."
    exit 1
fi

# Create build directory
BUILD_DIR="build"
if [ -d "$BUILD_DIR" ]; then
    echo "Cleaning build directory..."
    rm -rf "$BUILD_DIR"
fi

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Configure with CMake
echo "Configuring project with CMake..."
cmake .. -DCMAKE_BUILD_TYPE=Release

# Build
echo "Building project..."
make -j$(nproc)

echo ""
echo "=== Build Complete ==="
echo "Executable: $BUILD_DIR/SmartParkingUI"
echo ""
echo "To run: ./$BUILD_DIR/SmartParkingUI"

