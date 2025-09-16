import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:preload_page_view/preload_page_view.dart';  // Commented out due to dependency issues
import '../providers/recommendation_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../models/card.dart' as card_model;
import '../models/location_context.dart';
import '../widgets/enhanced_card_widget.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart' as custom;
import '../services/interaction_batcher.dart';
import '../utils/url_utils.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  final List<String> _viewedItems = [];
  DateTime _viewStartTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(_onPageChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFeed();
    });
  }


  Future<void> _refreshFeedWithLocation(LocationContext location) async {
    final authState = ref.read(authProvider);
    final userId = authState.user?.id ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';
    
    print('🔍 FeedScreen: Refreshing feed with location: ${location.city}, ${location.country}');
    
    await ref.read(recommendationProvider.notifier).loadRecommendationFeed(
      userId: userId,
      limit: 5,
      refresh: true,
      location: location,
    );
  }


  Future<void> _initializeFeed() async {
    final authState = ref.read(authProvider);
    final userId = authState.user?.id ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';
    
    print('🔍 FeedScreen: Initializing feed for user: $userId');
    
    // Wait for location detection to complete
    final locationState = ref.read(locationProvider);
    if (locationState.isDetecting) {
      print('🔍 FeedScreen: Location is still being detected, waiting...');
      // Wait for location detection to complete
      await Future.delayed(Duration(seconds: 2));
    }
    
    final currentLocationState = ref.read(locationProvider);
    print('🔍 FeedScreen: Location state: ${currentLocationState.location?.city}, ${currentLocationState.location?.country}');
    print('🔍 FeedScreen: Location detecting: ${currentLocationState.isDetecting}');
    print('🔍 FeedScreen: Location error: ${currentLocationState.error}');
    
    // Use recommendation algorithm with location data
    await ref.read(recommendationProvider.notifier).loadRecommendationFeed(
      userId: userId,
      limit: 5,
      refresh: false,
      location: currentLocationState.location,
    );
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged() {
    if (!_pageController.hasClients) return;
    
    final currentPage = _pageController.page ?? 0;
    final currentIndex = currentPage.round();
    
    if (currentIndex != _currentIndex) {
      _onItemViewed(currentIndex);
    }
  }

  void _onItemViewed(int index) {
    
    if (index != _currentIndex) {
      final recommendationState = ref.read(recommendationProvider);
      
      // Track dwell time for previous item
      if (_currentIndex < recommendationState.feed.length) {
        final previousItem = recommendationState.feed[_currentIndex];
        final contentId = previousItem['id']?.toString() ?? previousItem['card_id']?.toString();
        
        if (contentId != null && !_viewedItems.contains(contentId)) {
          // Track dwell time using batcher
          final authState = ref.read(authProvider);
          final userId = authState.user?.id ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';
          final dwellMs = DateTime.now().difference(_viewStartTime).inMilliseconds;
          
          if (dwellMs >= 5000) { // Only track if at least 5 seconds
            InteractionBatcher().trackInteraction(
              userId: userId,
              contentId: contentId,
              interactionType: 'dwell',
              metadata: {
                'dwell_ms': dwellMs,
                'position': _currentIndex,
                'timestamp': DateTime.now().toIso8601String(),
                'page': 'feed',
              },
            );
          }
          
          _viewedItems.add(contentId);
        }
      }
      
      // Start tracking time for new item
      _viewStartTime = DateTime.now();
      
      _currentIndex = index;
    }
    
    // Check pagination trigger - trigger when user reaches the last item
    final recommendationState = ref.read(recommendationProvider);
    final totalItems = recommendationState.feed.length;
    final triggerPoint = totalItems - 1; // Trigger when at the last item
    
    print("🔄 Pagination check: index=$index, totalItems=$totalItems, hasMore=${recommendationState.hasMore}, isLoadingMore=${recommendationState.isLoadingMore}");
    
    if (index >= triggerPoint && 
        recommendationState.hasMore && 
        !recommendationState.isLoadingMore) {
      print("📄 Loading more feed...");
      final locationState = ref.read(locationProvider);
      ref.read(recommendationProvider.notifier).loadMoreFeed(location: locationState.location);
    }
  }

  void _onCardAction(String cardId, String action) {
    // Handle next action by navigating to next page
    if (action == 'next') {
      final recommendationState = ref.read(recommendationProvider);
      if (_currentIndex < recommendationState.feed.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
      // Still track the interaction for analytics
    }
    
    // Track all interactions using batcher only
    final authState = ref.read(authProvider);
    final userId = authState.user?.id ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';
    InteractionBatcher().trackInteraction(
      userId: userId,
      contentId: cardId,
      interactionType: action,
      metadata: {
        'position': _currentIndex,
        'timestamp': DateTime.now().toIso8601String(),
        'source': 'flutter_app',
        'page': 'feed',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to location changes and refresh feed when location is detected
    ref.listen<LocationState>(locationProvider, (previous, next) {
      if (previous?.location == null && next.location != null) {
        print('🔍 FeedScreen: Location detected, refreshing feed...');
        _refreshFeedWithLocation(next.location!);
      }
    });

    final recommendationState = ref.watch(recommendationProvider);
    final authState = ref.watch(authProvider);
    final locationState = ref.watch(locationProvider);

    // Debug location state
    print('🔍 FeedScreen Build: Location state: ${locationState.location?.city}, ${locationState.location?.country}');
    print('🔍 FeedScreen Build: Location detecting: ${locationState.isDetecting}');
    print('🔍 FeedScreen Build: Location error: ${locationState.error}');

    if (recommendationState.isLoading && recommendationState.feed.isEmpty) {
      return const Scaffold(
        body: Center(child: LoadingWidget()),
      );
    }

    if (recommendationState.error != null && recommendationState.feed.isEmpty) {
      return Scaffold(
        body: Center(
          child: custom.ErrorWidget(
            message: recommendationState.error!,
            onRetry: () => ref.read(recommendationProvider.notifier).refreshFeed(),
          ),
        ),
      );
    }

    if (recommendationState.feed.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('No cards available'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Vertical TikTok-style feed with PageView
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: recommendationState.feed.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final item = recommendationState.feed[index];
                final cardData = item['card'] ?? item;
                
                if (cardData == null) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                
                // Convert Map to Card object if needed
                card_model.Card card;
                if (cardData is Map<String, dynamic>) {
                  try {
                    card = card_model.Card.fromJson(cardData);
                  } catch (e) {
                    // Fallback card creation
                    card = card_model.Card(
                      id: cardData['id']?.toString() ?? 'unknown_${DateTime.now().millisecondsSinceEpoch}',
                      createdAt: DateTime.now(),
                      locale: 'en',
                      occasion: cardData['occasion']?.toString() ?? 'general',
                      tags: [],
                      imageUrl: UrlUtils.getFullImageUrl(cardData['image_url']?.toString() ?? cardData['imageUrl']?.toString()),
                      thumbUrl: UrlUtils.getFullThumbnailUrl(cardData['thumb_url']?.toString() ?? cardData['image_url']?.toString()),
                      public: true,
                      ctr: 0.0,
                      saveRate: 0.0,
                      shareRate: 0.0,
                    );
                  }
                } else {
                  // Fallback for different data structures
                  card = card_model.Card(
                    id: cardData['id']?.toString() ?? 'unknown_${DateTime.now().millisecondsSinceEpoch}',
                    createdAt: DateTime.now(),
                    locale: 'en',
                    occasion: cardData['occasion']?.toString() ?? 'general',
                    tags: [],
                    imageUrl: UrlUtils.getFullImageUrl(cardData['image_url']?.toString() ?? cardData['imageUrl']?.toString()),
                    thumbUrl: UrlUtils.getFullThumbnailUrl(cardData['thumb_url']?.toString() ?? cardData['image_url']?.toString()),
                    public: true,
                    ctr: 0.0,
                    saveRate: 0.0,
                    shareRate: 0.0,
                  );
                }
                
                return EnhancedCardWidget(
                  card: card,
                  onAction: (action) => _onCardAction(card.id, action),
                );
              },
            ),
            // Loading indicator for pagination
            if (recommendationState.isLoadingMore)
              Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
            if (recommendationState.isLoading && recommendationState.feed.isNotEmpty)
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            // User info and recommendation status
            Positioned(
              top: 20,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User info
                  if (authState.user != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        authState.user!.isGuest 
                            ? 'Guest User' 
                            : authState.user!.displayName ?? 'User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  // Recommendation algorithm info
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.psychology,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'AI Recommended',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (recommendationState.isCached)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.cached,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Refresh button
            Positioned(
              top: 20,
              right: 20,
              child: GestureDetector(
                onTap: () async {
                  await ref.read(recommendationProvider.notifier).refreshFeed();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
