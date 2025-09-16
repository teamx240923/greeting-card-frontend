import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/location_context.dart';

class RecommendationState {
  final List<Map<String, dynamic>> feed;
  final String? userId;
  final bool isLoading;
  final String? error;
  final bool isCached;
  final String algorithm;
  final int count;
  final bool isLoadingMore;
  final bool hasMore;
  final String? nextCursor;

  RecommendationState({
    this.feed = const [],
    this.userId,
    this.isLoading = false,
    this.error,
    this.isCached = false,
    this.algorithm = 'tiktok_style',
    this.count = 0,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.nextCursor,
  });

  RecommendationState copyWith({
    List<Map<String, dynamic>>? feed,
    String? userId,
    bool? isLoading,
    String? error,
    bool? isCached,
    String? algorithm,
    int? count,
    bool? isLoadingMore,
    bool? hasMore,
    String? nextCursor,
  }) {
    return RecommendationState(
      feed: feed ?? this.feed,
      userId: userId ?? this.userId,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isCached: isCached ?? this.isCached,
      algorithm: algorithm ?? this.algorithm,
      count: count ?? this.count,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      nextCursor: nextCursor ?? this.nextCursor,
    );
  }
}

class RecommendationNotifier extends StateNotifier<RecommendationState> {
  final ApiService _apiService;
  String? _currentUserId;

  RecommendationNotifier(this._apiService) : super(RecommendationState());

  Future<void> loadRecommendationFeed({
    required String userId,
    int limit = 5,
    bool refresh = false,
    LocationContext? location,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    _currentUserId = userId;

    try {
      // Set location header if available
      if (location != null) {
        print('🌍 RecommendationProvider: Setting location header for loadRecommendationFeed');
        print('   Location: ${location.city}, ${location.region}, ${location.country}');
        print('   Confidence: ${location.confidence}');
        print('   Sources: ${location.source}');
        print('   Header: ${location.locationHeader}');
        _apiService.setLocationHeader(location.locationHeader);
      } else {
        print('🌍 RecommendationProvider: No location provided, clearing header');
        _apiService.clearLocationHeader();
      }

      final response = await _apiService.getForYouFeed(
        userId: userId,
        limit: limit,
        refresh: refresh,
      );

      final pagination = response['pagination'] ?? {};
      
      final feed = List<Map<String, dynamic>>.from(response['feed'] ?? []);
      final hasMore = pagination['has_more'] ?? false;
      final nextCursor = pagination['next_cursor'];
      
      
      state = state.copyWith(
        feed: feed,
        userId: response['user_id'],
        algorithm: response['algorithm'] ?? 'tiktok_style',
        count: response['count'] ?? 0,
        isCached: response['cached'] ?? false,
        isLoading: false,
        hasMore: hasMore,
        nextCursor: nextCursor,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }


  Future<void> loadMoreFeed({LocationContext? location}) async {
    print("🔄 loadMoreFeed called: userId=$_currentUserId, isLoadingMore=${state.isLoadingMore}, hasMore=${state.hasMore}");
    
    if (_currentUserId == null || state.isLoadingMore || !state.hasMore) {
      print("❌ loadMoreFeed blocked: userId=$_currentUserId, isLoadingMore=${state.isLoadingMore}, hasMore=${state.hasMore}");
      return;
    }

    state = state.copyWith(isLoadingMore: true, error: null);
    print("📡 Loading more feed with cursor: ${state.nextCursor}");

    try {
      // Set location header if available
      if (location != null) {
        print('🌍 RecommendationProvider: Setting location header for loadMoreFeed');
        print('   Location: ${location.city}, ${location.region}, ${location.country}');
        print('   Confidence: ${location.confidence}');
        print('   Sources: ${location.source}');
        print('   Header: ${location.locationHeader}');
        _apiService.setLocationHeader(location.locationHeader);
      } else {
        print('🌍 RecommendationProvider: No location provided for loadMoreFeed, clearing header');
        _apiService.clearLocationHeader();
      }

      final response = await _apiService.getForYouFeed(
        userId: _currentUserId!,
        limit: 5,
        refresh: false,
        cursor: state.nextCursor,
      );

      final pagination = response['pagination'] ?? {};
      final newFeed = List<Map<String, dynamic>>.from(response['feed'] ?? []);
      
      print("📄 Received ${newFeed.length} new cards, hasMore: ${pagination['has_more']}, nextCursor: ${pagination['next_cursor']}");
      
      state = state.copyWith(
        feed: [...state.feed, ...newFeed],
        isLoadingMore: false,
        hasMore: pagination['has_more'] ?? false,
        nextCursor: pagination['next_cursor'],
      );
      
      print("✅ Feed updated: total cards=${state.feed.length}, hasMore=${state.hasMore}");
      
    } catch (e) {
      print("❌ Error loading more feed: $e");
      state = state.copyWith(
        error: e.toString(),
        isLoadingMore: false,
      );
    }
  }

  Future<void> trackInteraction({
    required String contentId,
    required String interactionType,
    Map<String, dynamic>? metadata,
  }) async {
    if (_currentUserId == null) return;

    try {
      await _apiService.trackInteraction(
        userId: _currentUserId!,
        contentId: contentId,
        interactionType: interactionType,
        metadata: metadata,
      );
    } catch (e) {
      // Log error but don't show to user
      // Silently handle interaction tracking failures
    }
  }

  Future<void> refreshFeed({LocationContext? location}) async {
    if (_currentUserId == null) return;

    await loadRecommendationFeed(
      userId: _currentUserId!,
      refresh: true,
      location: location,
    );
  }

  Future<Map<String, dynamic>?> getUserStats() async {
    if (_currentUserId == null) return null;

    try {
      return await _apiService.getUserStats(userId: _currentUserId!);
    } catch (e) {
      // Silently handle user stats failures
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserInsights() async {
    if (_currentUserId == null) return null;

    try {
      return await _apiService.getUserInsights(userId: _currentUserId!);
    } catch (e) {
      // Silently handle user insights failures
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getTrendingContent({int limit = 5}) async {
    try {
      final response = await _apiService.getTrendingContent(limit: limit);
      return List<Map<String, dynamic>>.from(response['trending_content'] ?? []);
    } catch (e) {
      // Silently handle trending content failures
      return [];
    }
  }

  Future<Map<String, dynamic>?> getContentAnalytics(String contentId) async {
    try {
      return await _apiService.getContentAnalytics(contentId: contentId);
    } catch (e) {
      // Silently handle content analytics failures
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final recommendationProvider = StateNotifierProvider<RecommendationNotifier, RecommendationState>((ref) {
  return RecommendationNotifier(ApiService());
});
