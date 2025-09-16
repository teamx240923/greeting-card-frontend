#!/bin/bash

echo "🌐 Starting Flutter App for Web/Desktop Development..."
echo "🔗 Backend will auto-detect platform:"
echo "   - Web/Desktop: localhost:8000"
echo "   - Mobile: 192.168.1.24:8000"
echo "💡 Start backend first with: ./start_backend.sh"
echo ""

# Navigate to Flutter project directory
cd greeting-card-frontend

# Clean and get dependencies
echo "🧹 Cleaning Flutter project..."
flutter clean

echo "📦 Getting Flutter dependencies..."
flutter pub get

# Check for available devices
echo "💻 Checking for available devices..."
flutter devices

echo ""
echo "🚀 Starting Flutter app..."
echo "💻 Choose your target device (Chrome, Edge, etc.)"
echo "🛑 Press Ctrl+C to stop the app"
echo ""

# Run Flutter app for web
flutter run -d chrome
