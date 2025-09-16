import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/feed_item.dart';
import '../models/location_context.dart';
import '../services/api_service.dart';

class FeedState {
  final List<FeedItem> items;
  final String? sessionId;
  final String? nextCursor;
  final bool hasMore;
  final bool isLoading;
  final String? error;

  FeedState({
    this.items = const [],
    this.sessionId,
    this.nextCursor,
    this.hasMore = false,
    this.isLoading = false,
    this.error,
  });

  FeedState copyWith({
    List<FeedItem>? items,
    String? sessionId,
    String? nextCursor,
    bool? hasMore,
    bool? isLoading,
    String? error,
  }) {
    return FeedState(
      items: items ?? this.items,
      sessionId: sessionId ?? this.sessionId,
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class FeedNotifier extends StateNotifier<FeedState> {
  final ApiService _apiService;

  FeedNotifier(this._apiService) : super(FeedState());

  Future<void> createFeedSession({
    Map<String, dynamic>? filters,
    LocationContext? location,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Location context available for this session
      
      // Use TikTok-style feed API instead of old session-based API
      final response = await _apiService.getForYouFeed(
        userId: 'user-123', // You can make this dynamic based on user
        limit: 20,
        refresh: false,
      );
      
      final items = (response['feed'] as List)
          .map((item) => FeedItem.fromJson(item))
          .toList();
      
      state = state.copyWith(
        items: items,
        sessionId: 'tiktok-feed', // Use a simple identifier
        nextCursor: null, // TikTok feed doesn't use cursors
        hasMore: false, // For now, we'll implement pagination differently
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> loadMoreItems() async {
    if (state.isLoading) {
      return;
    }
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // For TikTok-style feed, we'll refresh the entire feed
      // In a real implementation, you might want to implement proper pagination
      final response = await _apiService.getForYouFeed(
        userId: 'user-123',
        limit: 20,
        refresh: true, // Force refresh to get new content
      );
      
      final newItems = (response['feed'] as List)
          .map((item) => FeedItem.fromJson(item))
          .toList();
      
      state = state.copyWith(
        items: newItems, // Replace with fresh content
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> refreshFeed() async {
    state = FeedState();
    await createFeedSession();
  }

  Future<void> trackInteraction({
    required String contentId,
    required String interactionType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _apiService.trackInteraction(
        userId: 'user-123',
        contentId: contentId,
        interactionType: interactionType,
        metadata: metadata,
      );
    } catch (e) {
      // Don't show error to user for interaction tracking
      // Silently handle interaction tracking failures
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  return FeedNotifier(ref.read(apiServiceProvider));
});
