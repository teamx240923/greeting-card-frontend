import '../utils/url_utils.dart';

enum MediaType { image, video, audio }

class Card {
  final String id;
  final DateTime createdAt;
  final String locale;
  final String occasion;
  final List<String> tags;
  final String imageUrl;
  final String thumbUrl;
  final String? model;
  final int? seed;
  final String? prompt;
  final String? negPrompt;
  final bool public;
  final double ctr;
  final double saveRate;
  final double shareRate;
  final MediaType mediaType;
  final String? videoUrl;
  final String? audioUrl;
  final Duration? duration;

  Card({
    required this.id,
    required this.createdAt,
    required this.locale,
    required this.occasion,
    required this.tags,
    required this.imageUrl,
    required this.thumbUrl,
    this.model,
    this.seed,
    this.prompt,
    this.negPrompt,
    required this.public,
    required this.ctr,
    required this.saveRate,
    required this.shareRate,
    this.mediaType = MediaType.image,
    this.videoUrl,
    this.audioUrl,
    this.duration,
  });

  factory Card.fromJson(Map<String, dynamic> json) {
    // Determine media type based on available URLs
    MediaType mediaType = MediaType.image;
    if (json['video_url'] != null) {
      mediaType = MediaType.video;
    } else if (json['audio_url'] != null) {
      mediaType = MediaType.audio;
    }
    
    // Parse duration if available
    Duration? duration;
    if (json['duration'] != null) {
      final durationSeconds = json['duration'] is int 
          ? json['duration'] 
          : int.tryParse(json['duration'].toString());
      if (durationSeconds != null) {
        duration = Duration(seconds: durationSeconds);
      }
    }
    
    return Card(
      id: json['id']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      locale: json['locale']?.toString() ?? 'en',
      occasion: json['occasion']?.toString() ?? 'general',
      tags: List<String>.from(json['tags'] ?? []),
      imageUrl: UrlUtils.getFullImageUrl(json['image_url']?.toString()),
      thumbUrl: UrlUtils.getFullThumbnailUrl(json['thumb_url']?.toString() ?? json['image_url']?.toString()),
      model: json['model']?.toString(),
      seed: json['seed'] is int ? json['seed'] : null,
      prompt: json['prompt']?.toString(),
      negPrompt: json['neg_prompt']?.toString(),
      public: json['public'] ?? true,
      ctr: (json['ctr'] ?? 0.0).toDouble(),
      saveRate: (json['save_rate'] ?? 0.0).toDouble(),
      shareRate: (json['share_rate'] ?? 0.0).toDouble(),
      mediaType: mediaType,
      videoUrl: json['video_url']?.toString(),
      audioUrl: json['audio_url']?.toString(),
      duration: duration,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'locale': locale,
      'occasion': occasion,
      'tags': tags,
      'image_url': imageUrl,
      'thumb_url': thumbUrl,
      'model': model,
      'seed': seed,
      'prompt': prompt,
      'neg_prompt': negPrompt,
      'public': public,
      'ctr': ctr,
      'save_rate': saveRate,
      'share_rate': shareRate,
      'media_type': mediaType.name,
      'video_url': videoUrl,
      'audio_url': audioUrl,
      'duration': duration?.inSeconds,
    };
  }
}
