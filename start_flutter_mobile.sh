#!/bin/bash

# Auto-detect current IP for mobile access
CURRENT_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}')

echo "📱 Starting Flutter App for Mobile Testing..."
echo "🔗 Backend will auto-detect platform:"
echo "   - Web/Desktop: localhost:8000"
echo "   - Mobile: $CURRENT_IP:8000"
echo "📋 Make sure your mobile device is connected via USB or WiFi"
echo "💡 Start backend first with: ./start_backend.sh"
echo ""

# Update API config with current IP
CONFIG_FILE="greeting-card-frontend/lib/config/api_config.dart"
if [ -f "$CONFIG_FILE" ]; then
    echo "🔄 Updating API configuration with current IP: $CURRENT_IP"
    sed -i.bak "s/http:\/\/192\.168\.1\.[0-9]*:8000/http:\/\/$CURRENT_IP:8000/g" "$CONFIG_FILE"
    sed -i.bak "s/192\.168\.1\.[0-9]*:8000/$CURRENT_IP:8000/g" "$CONFIG_FILE"
    rm -f "$CONFIG_FILE.bak"
    echo "✅ API configuration updated"
    echo ""
fi

# Navigate to Flutter project directory
cd greeting-card-frontend

# Clean and get dependencies
echo "🧹 Cleaning Flutter project..."
flutter clean

echo "📦 Getting Flutter dependencies..."
flutter pub get

# Check for connected devices
echo "📱 Checking for connected devices..."
flutter devices

echo ""
echo "🚀 Starting Flutter app..."
echo "📱 Choose your mobile device from the list above"
echo "🛑 Press Ctrl+C to stop the app"
echo ""

# Run Flutter app
flutter run
