# 🎊 GreetingCard Frontend

A Flutter-based frontend for the GreetingCard application with TikTok-style infinite feed, AI-powered content generation, and real-time personalization.

## 🚀 Quick Start

### **Prerequisites**
- Flutter SDK 3.16+
- Dart SDK
- Android Studio / Xcode (for mobile development)
- VS Code (recommended)

### **Installation**
```bash
# Clone repository
git clone https://github.com/yourusername/greeting-card-frontend.git
cd greeting-card-frontend

# Install dependencies
flutter pub get

# Run on web
./start_flutter_web.sh

# Run on mobile
./start_flutter_mobile.sh
```

### **Access Points**
- **🌐 Web App**: http://localhost:3000
- **📱 Mobile**: Auto-detects IP for mobile access
- **🔧 API Backend**: http://localhost:8000

## ✨ Key Features

### **🎯 TikTok-Style Infinite Feed**
- **Vertical Paging**: Swipe up/down to navigate content
- **Real-time Personalization**: Recommendations based on user interactions
- **Engagement Tracking**: Like, share, save, comment, view tracking
- **Smart Pagination**: Cursor-based pagination with infinite scroll

### **🤖 AI-Powered Content Generation**
- **Multi-format Support**: Images, videos, and audio content
- **Style Variety**: Modern, traditional, minimalist, vibrant styles
- **Occasion-aware**: Birthday, anniversary, festival, motivation cards
- **Real-time Generation**: On-demand content creation

### **🌍 Multi-Platform Support**
- **Web**: Chrome, Firefox, Safari
- **Mobile**: Android, iOS
- **Desktop**: Windows, macOS, Linux
- **Responsive Design**: Adapts to all screen sizes

## 🏗️ Project Structure

```
lib/
├── main.dart                 # App entry point
├── material_app.dart         # Material app configuration
├── config/                   # Configuration files
│   └── api_config.dart       # API configuration
├── models/                   # Data models
│   ├── card.dart            # Card model
│   ├── user.dart            # User model
│   ├── event.dart           # Event model
│   └── feed.dart            # Feed model
├── providers/                # State management
│   ├── user_provider.dart   # User state
│   ├── feed_provider.dart   # Feed state
│   ├── auth_provider.dart   # Authentication state
│   └── theme_provider.dart  # Theme state
├── screens/                  # UI screens
│   ├── home_screen.dart     # Main feed screen
│   ├── settings_screen.dart # Settings screen
│   ├── profile_screen.dart  # Profile screen
│   └── splash_screen.dart   # Splash screen
├── services/                 # API services
│   ├── api_service.dart     # Main API service
│   ├── auth_service.dart    # Authentication service
│   ├── feed_service.dart    # Feed service
│   └── storage_service.dart # Local storage service
├── utils/                    # Utility functions
│   └── constants.dart       # App constants
└── widgets/                  # Reusable widgets
    ├── card_widget.dart     # Card display widget
    ├── feed_widget.dart     # Feed widget
    └── loading_widget.dart  # Loading indicators
```

## 🛠️ Development Setup

### **Web Development**
```bash
# Start web development server
./start_flutter_web.sh

# Or manually
flutter run -d chrome
```

### **Mobile Development**
```bash
# Start mobile development
./start_flutter_mobile.sh

# Or manually
flutter run
```

### **Desktop Development**
```bash
# Run on desktop
flutter run -d windows
flutter run -d macos
flutter run -d linux
```

## 🔧 Configuration

### **API Configuration**
```dart
// lib/config/api_config.dart
class ApiConfig {
  static const String baseUrl = 'http://localhost:8000';
  static const String mobileUrl = 'http://192.168.1.24:8000';
  static const String version = 'v1';
  static const String fullUrl = '$baseUrl/$version';
}
```

### **Environment Configuration**
```dart
// lib/config/environment.dart
class Environment {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
  
  static const bool isProduction = bool.fromEnvironment('PRODUCTION', defaultValue: false);
}
```

## 🧪 Testing

### **Run Tests**
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run with coverage
flutter test --coverage
```

### **Test on Different Platforms**
```bash
# Test on web
flutter test -d chrome

# Test on mobile
flutter test -d android
flutter test -d ios
```

## 🚀 Building for Production

### **Web Build**
```bash
# Build for web
flutter build web --release

# Build with specific configuration
flutter build web --release --web-renderer html
```

### **Mobile Build**
```bash
# Build Android APK
flutter build apk --release

# Build Android App Bundle
flutter build appbundle --release

# Build iOS
flutter build ios --release
```

### **Desktop Build**
```bash
# Build Windows
flutter build windows --release

# Build macOS
flutter build macos --release

# Build Linux
flutter build linux --release
```

## 📱 Platform-Specific Features

### **Android**
- **Permissions**: Camera, storage, location
- **Native Features**: Share, notifications
- **Performance**: Optimized for mobile devices

### **iOS**
- **Permissions**: Camera, storage, location
- **Native Features**: Share, notifications
- **Performance**: Optimized for mobile devices

### **Web**
- **PWA Support**: Progressive Web App features
- **Responsive Design**: Adapts to all screen sizes
- **Performance**: Optimized for web browsers

## 🎨 UI/UX Features

### **TikTok-Style Feed**
- **Vertical Scrolling**: Smooth vertical page view
- **Gesture Support**: Swipe, tap, long press
- **Loading States**: Skeleton loading and spinners
- **Error Handling**: User-friendly error messages

### **Theme Support**
- **Light Theme**: Clean and modern design
- **Dark Theme**: Easy on the eyes
- **Custom Themes**: Brand-specific themes
- **Responsive**: Adapts to screen size

### **Accessibility**
- **Screen Reader**: Full screen reader support
- **Keyboard Navigation**: Complete keyboard support
- **High Contrast**: High contrast mode support
- **Font Scaling**: Dynamic font scaling

## 🔗 API Integration

### **Authentication**
```dart
// Guest login
final user = await AuthService.guestLogin();

// User registration
final user = await AuthService.register(email, password);

// User login
final user = await AuthService.login(email, password);
```

### **Feed Management**
```dart
// Get personalized feed
final feed = await FeedService.getFeed(userId);

// Track user interaction
await FeedService.trackInteraction(userId, contentId, 'like');

// Get user insights
final insights = await FeedService.getUserInsights(userId);
```

### **Content Generation**
```dart
// Generate content
final content = await ContentService.generateContent(request);

// Get generated content
final content = await ContentService.getGeneratedContent(filters);
```

## 📊 Performance Optimization

### **Image Caching**
```dart
// Cached network image
CachedNetworkImage(
  imageUrl: card.imageUrl,
  placeholder: (context, url) => LoadingWidget(),
  errorWidget: (context, url, error) => ErrorWidget(),
)
```

### **State Management**
```dart
// Riverpod providers
final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  return FeedNotifier();
});

// Consumer widget
Consumer(
  builder: (context, ref, child) {
    final feed = ref.watch(feedProvider);
    return FeedWidget(feed: feed);
  },
)
```

## 🔒 Security

### **Data Protection**
- **Secure Storage**: Flutter Secure Storage for sensitive data
- **API Security**: HTTPS for all API calls
- **Input Validation**: Client-side validation
- **Error Handling**: Secure error messages

### **Privacy**
- **No GPS Tracking**: Only coarse location data
- **User Control**: Complete privacy controls
- **Data Encryption**: All data encrypted in transit
- **GDPR Compliance**: User data deletion support

## 🤝 Contributing

### **Development Workflow**
1. Fork the repository
2. Create feature branch: `git checkout -b feature/new-feature`
3. Make changes and add tests
4. Run test suite: `flutter test`
5. Submit pull request

### **Coding Standards**
- **Dart**: Effective Dart guidelines
- **Flutter**: Flutter best practices
- **Git**: Conventional commit messages
- **Testing**: Widget and unit tests

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🔗 Related Repositories

- **Backend**: [greeting-card-backend](https://github.com/yourusername/greeting-card-backend)

## 📚 Documentation

- [Frontend Guide](docs/FRONTEND_GUIDE.md) - Complete frontend development guide
- [Architecture](docs/ARCHITECTURE.md) - System architecture overview
- [Deployment](docs/DEPLOYMENT.md) - Deployment instructions

## 🆘 Support

For support and questions:
- Create an issue in this repository
- Check the [documentation](https://github.com/yourusername/greeting-card-docs)
- Contact the development team

---

**Built with ❤️ using Flutter and Dart**