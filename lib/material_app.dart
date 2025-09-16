import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config/api_config.dart';
import 'models/event.dart';
import 'services/api_service.dart';
import 'services/interaction_batcher.dart';
import 'utils/url_utils.dart';
import 'providers/recommendation_provider.dart';

class MaterialGreetingCardApp extends ConsumerWidget {
  const MaterialGreetingCardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Greeting Card App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),
      home: const MaterialHomePage(),
    );
  }
}

class _AnimatedActionButton extends StatefulWidget {
  final String contentId;
  final String interactionType;
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Function(String, String) onPressed;

  const _AnimatedActionButton({
    required this.contentId,
    required this.interactionType,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  @override
  State<_AnimatedActionButton> createState() => _AnimatedActionButtonState();
}

class _AnimatedActionButtonState extends State<_AnimatedActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _colorAnimation = ColorTween(
      begin: widget.backgroundColor,
      end: widget.backgroundColor.withOpacity(0.8),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() {
      _isActive = !_isActive;
    });
    
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    
    widget.onPressed(widget.contentId, widget.interactionType);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: ElevatedButton.icon(
            onPressed: _handleTap, // Use _handleTap directly
            style: ElevatedButton.styleFrom(
              backgroundColor: _colorAnimation.value,
              foregroundColor: widget.foregroundColor,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: Icon(
              widget.icon,
              size: 18,
              color: _isActive ? Colors.yellow : widget.foregroundColor,
            ),
            label: Text(
              widget.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _isActive ? Colors.yellow : widget.foregroundColor,
              ),
            ),
          ),
        );
      },
    );
  }
}

class MaterialHomePage extends ConsumerStatefulWidget {
  const MaterialHomePage({super.key});

  @override
  ConsumerState<MaterialHomePage> createState() => _MaterialHomePageState();
}

class _MaterialHomePageState extends ConsumerState<MaterialHomePage> {
  List<Map<String, dynamic>> _cards = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _nextCursor;
  String _userName = '';
  String _userProfession = '';
  String? _userPhotoUrl;
  final ScrollController _scrollController = ScrollController();
  final ApiService _apiService = ApiService();
  late final String _userId; // Store guest ID for consistency
  
  // Dwell tracking
  final Map<String, DateTime> _cardViewStartTimes = {};
  final Map<String, Timer> _cardDwellTimers = {};
  final Set<String> _trackedDwellCards = {};

  @override
  void initState() {
    super.initState();
    _userId = 'guest_${DateTime.now().millisecondsSinceEpoch}'; // Generate consistent guest ID
    ApiConfig.printConfig(); // Print which endpoint is being used
    _loadCards();
    _scrollController.addListener(_onScroll);
    
    // Update visible cards after initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateVisibleCards();
    });
  }



  @override
  void dispose() {
    _scrollController.dispose();
    
    // Cancel all dwell timers
    for (final timer in _cardDwellTimers.values) {
      timer.cancel();
    }
    _cardDwellTimers.clear();
    _cardViewStartTimes.clear();
    _trackedDwellCards.clear();
    
    // Flush any pending interactions before disposing
    InteractionBatcher().flush();
    super.dispose();
  }

  void _onScroll() {
    // Check for pagination
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreCards();
    }
    
    // Update visible cards for dwell tracking
    _updateVisibleCards();
  }
  
  void _updateVisibleCards() {
    if (!_scrollController.hasClients) return;
    
    final scrollOffset = _scrollController.offset;
    final viewportHeight = _scrollController.position.viewportDimension;
    
    // Calculate visible range (with some padding)
    final cardHeight = 400.0; // Approximate card height
    final padding = 16.0; // Card padding
    final startIndex = ((scrollOffset - padding) / (cardHeight + padding)).floor().clamp(0, _cards.length - 1);
    final endIndex = ((scrollOffset + viewportHeight + padding) / (cardHeight + padding)).ceil().clamp(0, _cards.length);
    
    // Track visible cards
    for (int i = startIndex; i < endIndex; i++) {
      if (i < _cards.length) {
        final cardId = _cards[i]['id'];
        if (!_cardViewStartTimes.containsKey(cardId)) {
          _startTrackingCard(cardId);
        }
      }
    }
    
    // Stop tracking cards that are no longer visible
    final visibleCardIds = <String>{};
    for (int i = startIndex; i < endIndex; i++) {
      if (i < _cards.length) {
        visibleCardIds.add(_cards[i]['id']);
      }
    }
    
    // Stop tracking cards that are no longer visible
    for (final cardId in _cardViewStartTimes.keys.toList()) {
      if (!visibleCardIds.contains(cardId)) {
        _stopTrackingCard(cardId);
      }
    }
  }
  
  void _startTrackingCard(String cardId) {
    if (_cardViewStartTimes.containsKey(cardId)) return;
    
    _cardViewStartTimes[cardId] = DateTime.now();
    
    // Set up dwell timer
    _cardDwellTimers[cardId] = Timer(const Duration(seconds: 5), () {
      _trackDwellForCard(cardId);
    });
  }
  
  void _stopTrackingCard(String cardId) {
    if (!_cardViewStartTimes.containsKey(cardId)) return;
    
    // Cancel timer
    _cardDwellTimers[cardId]?.cancel();
    _cardDwellTimers.remove(cardId);
    
    // Remove from tracking
    _cardViewStartTimes.remove(cardId);
  }
  
  void _trackDwellForCard(String cardId) {
    if (_trackedDwellCards.contains(cardId)) return;
    if (!_cardViewStartTimes.containsKey(cardId)) return;
    
    final startTime = _cardViewStartTimes[cardId]!;
    final dwellMs = DateTime.now().difference(startTime).inMilliseconds;
    
    if (dwellMs >= 5000) {
      _trackedDwellCards.add(cardId);
      
      InteractionBatcher().trackInteraction(
        userId: _userId,
        contentId: cardId,
        interactionType: 'dwell',
        metadata: {
          'dwell_ms': dwellMs,
          'timestamp': DateTime.now().toIso8601String(),
          'source': 'flutter_app',
          'page': 'cards',
        }
      );
    }
  }

  Future<void> _loadMoreCards() async {
    if (_isLoadingMore || !_hasMore) return;
    
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final feedResponse = await http.get(
        Uri.parse('${ApiConfig.feedUrl}/for-you/$_userId?limit=5&cursor=${_nextCursor ?? ''}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (feedResponse.statusCode == 200) {
        final data = jsonDecode(feedResponse.body);
        final newCards = List<Map<String, dynamic>>.from(data['feed']);
        final pagination = data['pagination'] ?? {};
        
        setState(() {
          _cards.addAll(newCards);
          _hasMore = pagination['has_more'] ?? false;
          _nextCursor = pagination['next_cursor']?.toString();
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }


  Future<void> _loadCards() async {
    try {
      // Use TikTok-style feed API
      final feedResponse = await http.get(
        Uri.parse('${ApiConfig.feedUrl}/for-you/$_userId?limit=5'),
        headers: {'Content-Type': 'application/json'},
      );

      if (feedResponse.statusCode == 200) {
        final data = jsonDecode(feedResponse.body);
        final pagination = data['pagination'] ?? {};
        
        setState(() {
          _cards = List<Map<String, dynamic>>.from(data['feed']);
          _hasMore = pagination['has_more'] ?? false;
          _nextCursor = pagination['next_cursor']?.toString();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text(
          'Greeting',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: const Color(0xFFF7F7F7),
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: const Color(0xFFF7F7F7),
        scrolledUnderElevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading greeting cards...'),
                ],
              ),
            )
          : _cards.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.card_giftcard_outlined,
                        size: 64,
                        color: colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No cards available',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pull to refresh or check your connection',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _loadCards,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : _buildMainContent(context, colorScheme),
    );
  }

  Widget _buildMainContent(BuildContext context, ColorScheme colorScheme) {
    return Column(
      children: [
        // Filter Chips
        
        // Vertical List of Images
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadCards,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _cards.length + (_isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _cards.length) {
                  // Loading indicator at the bottom
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                
                final card = _cards[index];
                return _buildImageCard(context, card, colorScheme, index);
              },
            ),
          ),
        ),
      ],
    );
  }



  Widget _buildImageCard(BuildContext context, Map<String, dynamic> card, ColorScheme colorScheme, int index) {
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Card Container
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1a1a1a),
                        Color(0xFF000000),
                      ],
                    ),
                  ),
                  child: card['image_url'] != null
                      ? Image.network(
                          UrlUtils.getFullImageUrl(card['image_url']),
                          fit: BoxFit.contain,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildFallbackImage(card);
                          },
                        )
                      : _buildFallbackImage(card),
                ),
                
                // User Profile Card (seamless with image)
                GestureDetector(
                  onTap: _showEditProfileDialog,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE3E2DA),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Profile Picture - Show only if photo is uploaded OR if nothing is set
                        if (_userPhotoUrl != null && _userPhotoUrl!.isNotEmpty || 
                            (_userName.isEmpty && _userProfession.isEmpty)) ...[
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[300],
                              border: Border.all(
                                color: Colors.grey[400]!,
                                width: 1,
                              ),
                            ),
                            child: _userPhotoUrl != null && _userPhotoUrl!.isNotEmpty
                                ? ClipOval(
                                    child: Image.network(
                                      _userPhotoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.person,
                                          color: Colors.grey,
                                          size: 24,
                                        );
                                      },
                                    ),
                                  )
                                : const Icon(
                                    Icons.person,
                                    color: Colors.grey,
                                    size: 24,
                                  ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        
                        // User Info - Show only if name or profession is filled OR if nothing is set
                        if (_userName.isNotEmpty || _userProfession.isNotEmpty || 
                            (_userName.isEmpty && _userProfession.isEmpty)) ...[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Name - Show if filled OR if nothing is set
                                if (_userName.isNotEmpty || (_userName.isEmpty && _userProfession.isEmpty))
                                  Text(
                                    _userName.isNotEmpty ? _userName : 'Your Name',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF000000),
                                    ),
                                  ),
                                // Profession - Show if filled OR if nothing is set
                                if (_userProfession.isNotEmpty || (_userName.isEmpty && _userProfession.isEmpty)) ...[
                                  if (_userName.isNotEmpty || (_userName.isEmpty && _userProfession.isEmpty)) 
                                    const SizedBox(height: 2),
                                  Text(
                                    _userProfession.isNotEmpty ? _userProfession : 'Business name',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF000000),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                        
                        // Edit Button - Only show if user hasn't filled profile info
                        if (_userName.isEmpty && _userProfession.isEmpty)
                          OutlinedButton(
                            onPressed: _showEditProfileDialog,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFFD9D9D9)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(40),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            child: const Text(
                              'Edit',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Action Buttons Aligned with Card
        Container(
          margin: const EdgeInsets.only(top: 8, bottom: 24),
          child: Column(
            children: [
              // First row: Like, Dislike, Save
              Row(
                children: [
                  Expanded(
                    child: _buildAnimatedActionButton(
                      contentId: card['id'],
                      interactionType: 'like',
                      icon: Icons.favorite,
                      label: 'Like',
                      backgroundColor: const Color(0xFFE91E63),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildAnimatedActionButton(
                      contentId: card['id'],
                      interactionType: 'dislike',
                      icon: Icons.thumb_down,
                      label: 'Dislike',
                      backgroundColor: const Color(0xFF757575),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildAnimatedActionButton(
                      contentId: card['id'],
                      interactionType: 'save',
                      icon: Icons.bookmark,
                      label: 'Save',
                      backgroundColor: const Color(0xFF9C27B0),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Second row: Download, Share
              Row(
                children: [
                  Expanded(
                    child: _buildAnimatedActionButton(
                      contentId: card['id'],
                      interactionType: 'download',
                      icon: Icons.download,
                      label: 'Download',
                      backgroundColor: const Color(0xFF185CC3),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildAnimatedActionButton(
                      contentId: card['id'],
                      interactionType: 'share',
                      icon: Icons.share,
                      label: 'Share',
                      backgroundColor: const Color(0xFF008548),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackImage(Map<String, dynamic> card) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4A148C),
            Color(0xFF1A237E),
            Color(0xFF0D47A1),
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.card_giftcard,
          size: 60,
          color: Colors.white,
        ),
      ),
    );
  }



  void _showEditProfileDialog() {
    // Track profile edit started
    _trackEvent(Event(
      event: EventType.profile_edit_started,
      cardId: null,
      position: null,
      context: {
        'source': 'greetings_page',
        'has_existing_profile': _userName.isNotEmpty || _userProfession.isNotEmpty,
        'trigger': 'edit_button_clicked',
        'timestamp': DateTime.now().toIso8601String(),
      },
    ));

    final nameController = TextEditingController(text: _userName);
    final professionController = TextEditingController(text: _userProfession);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Text(
                'Edit banner info',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 24),
              
              // Add Photo Section
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        // TODO: Implement photo picker
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Photo picker coming soon!')),
                        );
                      },
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFF3270D2),
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _userPhotoUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  _userPhotoUrl!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt,
                                color: Color(0xFF3270D2),
                                size: 32,
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add Photo',
                      style: TextStyle(
                        color: Color(0xFF3270D2),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Note: This photo will be added in the poster',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Name Field
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: 'Name',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(100),
                    borderSide: const BorderSide(color: Color(0xFFEFEFEF)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(100),
                    borderSide: const BorderSide(color: Color(0xFFEFEFEF)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(100),
                    borderSide: const BorderSide(color: Color(0xFFEFEFEF)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              
              // Business Name Field
              TextField(
                controller: professionController,
                decoration: InputDecoration(
                  hintText: 'Business name (Optional)',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(100),
                    borderSide: const BorderSide(color: Color(0xFFEFEFEF)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(100),
                    borderSide: const BorderSide(color: Color(0xFFEFEFEF)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(100),
                    borderSide: const BorderSide(color: Color(0xFFEFEFEF)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 24),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final newName = nameController.text;
                    final newProfession = professionController.text;
                    final wasEmpty = _userName.isEmpty && _userProfession.isEmpty;
                    
                    setState(() {
                      _userName = newName;
                      _userProfession = newProfession;
                    });
                    
                    // Track profile edit completed
                    _trackEvent(Event(
                      event: EventType.profile_edit_completed,
                      cardId: null,
                      position: null,
                      context: {
                        'source': 'greetings_page',
                        'has_name': newName.isNotEmpty,
                        'has_profession': newProfession.isNotEmpty,
                        'completion_percentage': _calculateProfileCompletion(newName, newProfession),
                        'was_empty_before': wasEmpty,
                        'timestamp': DateTime.now().toIso8601String(),
                      },
                    ));
                    
                    // Track business card creation/update
                    if (newName.isNotEmpty || newProfession.isNotEmpty) {
                      _trackEvent(Event(
                        event: wasEmpty ? EventType.business_card_created : EventType.business_card_updated,
                        cardId: null,
                        position: null,
                        context: {
                          'has_name': newName.isNotEmpty,
                          'has_profession': newProfession.isNotEmpty,
                          'has_photo': _userPhotoUrl != null && _userPhotoUrl!.isNotEmpty,
                          'completion_percentage': _calculateProfileCompletion(newName, newProfession),
                          'timestamp': DateTime.now().toIso8601String(),
                        },
                      ));
                    }
                    
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF185CC3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  child: const Text(
                    'SAVE',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }




  // Animated action button for Greetings tab
  Widget _buildAnimatedActionButton({
    required String contentId,
    required String interactionType,
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return _AnimatedActionButton(
      contentId: contentId,
      interactionType: interactionType,
      icon: icon,
      label: label,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      onPressed: (id, type) => _trackInteraction(id, type),
    );
  }

  double _calculateProfileCompletion(String name, String profession) {
    int completed = 0;
    int total = 3; // name, profession, photo
    
    if (name.isNotEmpty) completed++;
    if (profession.isNotEmpty) completed++;
    if (_userPhotoUrl != null && _userPhotoUrl!.isNotEmpty) completed++;
    
    return (completed / total) * 100;
  }

  void _trackEvent(Event event) {
    try {
      _apiService.logEvent(event);
    } catch (e) {
      // Silently handle event tracking failures
    }
  }

  Future<void> _trackInteraction(String contentId, String interactionType) async {
    // Use batched tracking only for consistency and performance
    InteractionBatcher().trackInteraction(
      userId: _userId,
      contentId: contentId,
      interactionType: interactionType,
      metadata: {
        'timestamp': DateTime.now().toIso8601String(),
        'source': 'flutter_app',
        'page': 'cards',
      }
    );

    // Track content customization for download and share actions
    if (interactionType == 'download' || interactionType == 'share') {
      final hasUserInfo = _userName.isNotEmpty || _userProfession.isNotEmpty;
      final hasProfilePic = _userPhotoUrl != null && _userPhotoUrl!.isNotEmpty;
      
      if (hasUserInfo) {
        _trackEvent(Event(
          event: EventType.content_customized,
          cardId: contentId,
          position: null,
          context: {
            'customization_type': 'business_card_overlay',
            'has_user_info': hasUserInfo,
            'has_profile_pic': hasProfilePic,
            'customization_depth': hasProfilePic ? 'full' : 'partial',
            'action': interactionType,
            'timestamp': DateTime.now().toIso8601String(),
          },
        ));
      }
    }
  }

}
