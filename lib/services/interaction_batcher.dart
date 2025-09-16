import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class InteractionBatcher {
  static final InteractionBatcher _instance = InteractionBatcher._internal();
  factory InteractionBatcher() => _instance;
  InteractionBatcher._internal();

  final List<Map<String, dynamic>> _pendingInteractions = [];
  Timer? _batchTimer;
  static const int _batchSize = 10;  // Smaller batch for faster processing
  static const Duration _batchDelay = Duration(seconds: 3);  // Shorter delay for better responsiveness

  void trackInteraction({
    required String userId,
    required String contentId,
    required String interactionType,
    Map<String, dynamic>? metadata,
  }) {
    // Add interaction to batch
    _pendingInteractions.add({
      'user_id': userId,
      'content_id': contentId,
      'interaction_type': interactionType,
      'metadata': {
        ...?metadata,
        'timestamp': DateTime.now().toIso8601String(),
        'source': 'flutter_app',
      }
    });

    // Start batch timer if not already running
    _batchTimer ??= Timer(_batchDelay, _processBatch);

    // Process immediately if batch is full
    if (_pendingInteractions.length >= _batchSize) {
      _batchTimer?.cancel();
      _batchTimer = null;
      _processBatch();
    }
  }

  Future<void> _processBatch() async {
    if (_pendingInteractions.isEmpty) return;

    final interactions = List<Map<String, dynamic>>.from(_pendingInteractions);
    _pendingInteractions.clear();
    _batchTimer?.cancel();
    _batchTimer = null;

    try {
      await _sendBatchInteractions(interactions);
    } catch (e) {
      // Silently handle batch interaction failures
      // Optionally retry or store for later
    }
  }

  Future<void> _sendBatchInteractions(List<Map<String, dynamic>> interactions) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/v1/feed/interactions/batch'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'interactions': interactions,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Batch interaction failed: ${response.statusCode}');
    }
  }

  // Force flush any pending interactions
  Future<void> flush() async {
    if (_pendingInteractions.isNotEmpty) {
      _batchTimer?.cancel();
      _batchTimer = null;
      await _processBatch();
    }
  }

  // Get current batch size for debugging
  int get pendingCount => _pendingInteractions.length;
}
