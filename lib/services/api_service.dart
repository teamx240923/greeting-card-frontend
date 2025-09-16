import 'package:dio/dio.dart';
import '../models/user.dart';
import '../models/card.dart';
import '../models/feed_item.dart';
import '../models/event.dart';
import '../models/location_context.dart';
import '../config/api_config.dart';

class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  // Auth endpoints
  Future<Map<String, dynamic>> createGuestSession({
    required String deviceId,
    String? displayName,
    String? brandColor,
    String qrType = 'none',
    String? qrValue,
  }) async {
    final response = await _dio.post('/v1/auth/guest', data: {
      'device_id': deviceId,
      'display_name': displayName,
      'brand_color': brandColor,
      'qr_type': qrType,
      'qr_value': qrValue,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> upgradeAccount({
    required String authType,
    String? email,
    String? phone,
    String? displayName,
  }) async {
    final response = await _dio.post('/v1/auth/upgrade', data: {
      'auth_type': authType,
      'email': email,
      'phone': phone,
      'display_name': displayName,
    });
    return response.data;
  }

  // Feed endpoints
  Future<Map<String, dynamic>> createFeedSession({
    Map<String, dynamic>? filters,
  }) async {
    final response = await _dio.post('/v1/feed/session', data: {
      'filters': filters,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getFeedPage({
    required String sessionId,
    String? cursor,
    int limit = 20,
  }) async {
    final response = await _dio.post('/v1/feed/page', data: {
      'session_id': sessionId,
      'cursor': cursor,
      'limit': limit,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getTodayCards({
    String locale = 'en',
    String? occasion,
  }) async {
    final response = await _dio.get('/v1/feed/today', queryParameters: {
      'locale': locale,
      'occasion': occasion,
    });
    return response.data;
  }

  // TikTok-style Recommendation endpoints
  Future<Map<String, dynamic>> getForYouFeed({
    required String userId,
    int limit = 20,
    bool refresh = false,
    String? cursor,
  }) async {
    final response = await _dio.get('/v1/feed/for-you/$userId', queryParameters: {
      'limit': limit,
      'refresh': refresh,
      if (cursor != null) 'cursor': cursor,
    });
    return response.data;
  }


  Future<Map<String, dynamic>> trackInteraction({
    required String userId,
    required String contentId,
    required String interactionType,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await _dio.post('/v1/feed/interaction', data: {
      'user_id': userId,
      'content_id': contentId,
      'interaction_type': interactionType,
      'metadata': metadata,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getUserStats({
    required String userId,
  }) async {
    final response = await _dio.get('/v1/feed/user/$userId/stats');
    return response.data;
  }

  Future<Map<String, dynamic>> getUserInsights({
    required String userId,
  }) async {
    final response = await _dio.get('/v1/feed/user/$userId/insights');
    return response.data;
  }

  Future<Map<String, dynamic>> getTrendingContent({
    int limit = 10,
  }) async {
    final response = await _dio.get('/v1/feed/trending', queryParameters: {
      'limit': limit,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getContentAnalytics({
    required String contentId,
  }) async {
    final response = await _dio.get('/v1/feed/content/$contentId/analytics');
    return response.data;
  }

  Future<Map<String, dynamic>> refreshUserFeed({
    required String userId,
  }) async {
    final response = await _dio.post('/v1/feed/refresh/$userId');
    return response.data;
  }

  // Event endpoints
  Future<Map<String, dynamic>> logEvent(Event event) async {
    // Convert Event to EventCreate format for backend
    final eventData = {
      'event': event.event.value,
      'card_id': event.cardId,
      'session_id': event.sessionId,
      'dwell_ms': event.dwellMs,
      'position': event.position,
      'context': event.context,
    };
    
    final response = await _dio.post('/v1/event/', data: eventData);
    return response.data;
  }

  Future<List<Map<String, dynamic>>> logEvents(List<Event> events) async {
    final response = await _dio.post('/v1/event/batch', data: 
        events.map((e) => e.toJson()).toList());
    return List<Map<String, dynamic>>.from(response.data);
  }

  // AI generation endpoints
  Future<Map<String, dynamic>> createGenerationJob({
    required String occasion,
    required String locale,
    String? style,
    String? prompt,
  }) async {
    final response = await _dio.post('/v1/ai/generate', data: {
      'occasion': occasion,
      'locale': locale,
      'style': style,
      'prompt': prompt,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getGenerationJob(String jobId) async {
    final response = await _dio.get('/v1/ai/jobs/$jobId');
    return response.data;
  }

  // Branding endpoints
  Future<Map<String, dynamic>> composeBrandedCard({
    required String cardId,
    String? brandColor,
    String qrType = 'none',
    String? qrValue,
    String? logoUrl,
  }) async {
    final response = await _dio.post('/v1/brand/compose', data: {
      'card_id': cardId,
      'brand_color': brandColor,
      'qr_type': qrType,
      'qr_value': qrValue,
      'logo_url': logoUrl,
    });
    return response.data;
  }

  // Location endpoints
  Future<Map<String, dynamic>> resolveLocation(ClientLocationSignals signals) async {
    final response = await _dio.post('/v1/loc/resolve', data: {
      'client_signals': signals.toJson(),
      'force_refresh': false,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> resolveLocationWithGps({
    required double latitude,
    required double longitude,
    double? accuracy,
    double? altitude,
    double? heading,
    double? speed,
  }) async {
    final response = await _dio.post('/v1/loc/resolve-gps', data: {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'altitude': altitude,
      'heading': heading,
      'speed': speed,
    });
    return response.data;
  }

  Future<List<Map<String, dynamic>>> getRegionalFestivals({
    required String country,
    String? region,
    String? date,
  }) async {
    final response = await _dio.get('/v1/loc/festivals', queryParameters: {
      'country': country,
      'region': region,
      'date': date,
    });
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>> getLocaleMapping() async {
    final response = await _dio.get('/v1/loc/locale-mapping');
    return response.data;
  }

  // Set auth token
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // Clear auth token
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  // Set location header
  void setLocationHeader(String locationHeader) {
    print('🌍 ApiService: Setting location header: $locationHeader');
    _dio.options.headers['X-Location-Bucket'] = locationHeader;
    print('🌍 ApiService: Location header set in Dio options');
  }

  // Clear location header
  void clearLocationHeader() {
    print('🌍 ApiService: Clearing location header');
    _dio.options.headers.remove('X-Location-Bucket');
    print('🌍 ApiService: Location header cleared from Dio options');
  }
}
