# 🎊 GreetingCard Frontend Development Guide

Complete guide for developing the Flutter frontend of the GreetingCard application.

## 🏗️ Architecture Overview

The frontend is built using Flutter with a clean architecture pattern:

```
lib/
├── main.dart                 # App entry point
├── material_app.dart         # Material app configuration
├── config/                   # Configuration files
├── models/                   # Data models
├── providers/                # State management (Riverpod)
├── screens/                  # UI screens
├── services/                 # API services
├── utils/                    # Utility functions
└── widgets/                  # Reusable widgets
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.16+
- Dart SDK
- Android Studio / Xcode (for mobile development)
- VS Code (recommended)

### Installation
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

## 🎯 Key Features

### TikTok-Style Infinite Feed
The main feature is a vertical scrolling feed similar to TikTok:

```dart
// lib/screens/home_screen.dart
class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(feedProvider);
    
    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: feedState.cards.length,
      itemBuilder: (context, index) {
        return CardWidget(card: feedState.cards[index]);
      },
    );
  }
}
```

### State Management with Riverpod
```dart
// lib/providers/feed_provider.dart
final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  return FeedNotifier();
});

class FeedNotifier extends StateNotifier<FeedState> {
  FeedNotifier() : super(FeedState.initial());
  
  Future<void> loadFeed(String userId) async {
    state = state.copyWith(loading: true);
    try {
      final feed = await FeedService.getFeed(userId);
      state = state.copyWith(
        loading: false,
        cards: feed.cards,
        hasNext: feed.hasNext,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}
```

### API Integration
```dart
// lib/services/api_service.dart
class ApiService {
  static const String baseUrl = 'http://localhost:8000';
  
  static Future<List<Card>> getFeed(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/v1/feed/for-you/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['data']['feed'] as List)
          .map((json) => Card.fromJson(json))
          .toList();
    }
    throw Exception('Failed to load feed');
  }
}
```

## 📱 Platform-Specific Development

### Web Development
```bash
# Start web development server
flutter run -d chrome

# Build for web
flutter build web --release
```

**Web-specific features:**
- Responsive design for different screen sizes
- Keyboard navigation support
- PWA (Progressive Web App) features
- SEO optimization

### Mobile Development
```bash
# Run on Android
flutter run -d android

# Run on iOS
flutter run -d ios
```

**Mobile-specific features:**
- Touch gestures and animations
- Native sharing functionality
- Device-specific permissions
- Platform-specific UI components

### Desktop Development
```bash
# Run on Windows
flutter run -d windows

# Run on macOS
flutter run -d macos

# Run on Linux
flutter run -d linux
```

## 🎨 UI/UX Development

### Theme System
```dart
// lib/providers/theme_provider.dart
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system);
  
  void toggleTheme() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }
}
```

### Custom Widgets
```dart
// lib/widgets/card_widget.dart
class CardWidget extends StatelessWidget {
  final Card card;
  
  const CardWidget({Key? key, required this.card}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: CachedNetworkImageProvider(card.imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // Card content
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Text(
              card.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                shadows: [
                  Shadow(
                    offset: Offset(1, 1),
                    blurRadius: 3,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
          ),
          // Action buttons
          Positioned(
            right: 20,
            bottom: 80,
            child: Column(
              children: [
                IconButton(
                  onPressed: () => _likeCard(card.id),
                  icon: Icon(Icons.favorite, color: Colors.white),
                ),
                IconButton(
                  onPressed: () => _shareCard(card.id),
                  icon: Icon(Icons.share, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

## 🔧 Configuration

### Environment Configuration
```dart
// lib/config/environment.dart
class Environment {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
  
  static const String mobileUrl = String.fromEnvironment(
    'MOBILE_URL',
    defaultValue: 'http://192.168.1.24:8000',
  );
  
  static const bool isProduction = bool.fromEnvironment('PRODUCTION', defaultValue: false);
}
```

### API Configuration
```dart
// lib/config/api_config.dart
class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return Environment.apiBaseUrl;
    } else {
      return Environment.mobileUrl;
    }
  }
  
  static const String version = 'v1';
  static String get fullUrl => '$baseUrl/$version';
}
```

## 🧪 Testing

### Unit Tests
```dart
// test/services/api_service_test.dart
void main() {
  group('ApiService', () {
    test('getFeed returns list of cards', () async {
      // Mock HTTP response
      when(mockHttp.get(any)).thenAnswer(
        (_) async => http.Response(json.encode({
          'success': true,
          'data': {
            'feed': [
              {'id': '1', 'title': 'Test Card', 'image_url': 'test.jpg'}
            ]
          }
        }), 200),
      );
      
      final cards = await ApiService.getFeed('user123');
      expect(cards.length, 1);
      expect(cards.first.title, 'Test Card');
    });
  });
}
```

### Widget Tests
```dart
// test/widgets/card_widget_test.dart
void main() {
  testWidgets('CardWidget displays card title', (WidgetTester tester) async {
    final card = Card(
      id: '1',
      title: 'Test Card',
      imageUrl: 'test.jpg',
    );
    
    await tester.pumpWidget(
      MaterialApp(
        home: CardWidget(card: card),
      ),
    );
    
    expect(find.text('Test Card'), findsOneWidget);
  });
}
```

### Integration Tests
```dart
// integration_test/app_test.dart
void main() {
  group('App Integration Tests', () {
    testWidgets('User can scroll through feed', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Find the feed
      expect(find.byType(PageView), findsOneWidget);
      
      // Scroll down
      await tester.drag(find.byType(PageView), Offset(0, -500));
      await tester.pumpAndSettle();
      
      // Verify new card is visible
      expect(find.byType(CardWidget), findsWidgets);
    });
  });
}
```

## 🚀 Building for Production

### Web Build
```bash
# Build for web
flutter build web --release

# Build with specific configuration
flutter build web --release --web-renderer html --dart-define=API_BASE_URL=https://api.greetingcard.com
```

### Mobile Build
```bash
# Build Android APK
flutter build apk --release

# Build Android App Bundle
flutter build appbundle --release

# Build iOS
flutter build ios --release
```

### Desktop Build
```bash
# Build Windows
flutter build windows --release

# Build macOS
flutter build macos --release

# Build Linux
flutter build linux --release
```

## 📊 Performance Optimization

### Image Caching
```dart
// Use CachedNetworkImage for efficient image loading
CachedNetworkImage(
  imageUrl: card.imageUrl,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
  memCacheWidth: 400, // Optimize memory usage
  memCacheHeight: 600,
)
```

### State Management Optimization
```dart
// Use select to prevent unnecessary rebuilds
final feedCards = ref.watch(feedProvider.select((state) => state.cards));

// Use autoDispose for automatic disposal
final feedProvider = StateNotifierProvider.autoDispose<FeedNotifier, FeedState>((ref) {
  return FeedNotifier();
});
```

### Build Optimization
```yaml
# pubspec.yaml
flutter:
  uses-material-design: true
  assets:
    - assets/images/
  fonts:
    - family: CustomFont
      fonts:
        - asset: fonts/CustomFont-Regular.ttf
        - asset: fonts/CustomFont-Bold.ttf
          weight: 700
```

## 🔒 Security

### Secure Storage
```dart
// lib/services/storage_service.dart
class StorageService {
  static const _storage = FlutterSecureStorage();
  
  static Future<void> storeToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }
  
  static Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }
}
```

### API Security
```dart
// lib/services/api_service.dart
class ApiService {
  static Future<Map<String, String>> _getHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
```

## 🎯 Best Practices

### Code Organization
- Keep widgets small and focused
- Use meaningful names for variables and functions
- Follow Flutter naming conventions
- Use const constructors where possible

### State Management
- Use Riverpod for state management
- Keep state as minimal as possible
- Use providers for dependency injection
- Handle loading and error states

### Performance
- Use ListView.builder for large lists
- Implement lazy loading for images
- Use const constructors
- Avoid unnecessary rebuilds

### Testing
- Write unit tests for business logic
- Write widget tests for UI components
- Write integration tests for user flows
- Aim for high test coverage

## 🔗 Related Documentation

- [Backend API Reference](../backend/docs/API_REFERENCE.md)
- [Architecture Overview](ARCHITECTURE.md)
- [Deployment Guide](DEPLOYMENT.md)

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/new-feature`
3. Make changes and add tests
4. Run test suite: `flutter test`
5. Submit pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

