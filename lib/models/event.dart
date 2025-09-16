enum EventType {
  dwell,
  like,
  dislike,
  save,
  share,
  download,
  skip,
  report,
  // High-priority profile and business card tracking
  profile_edit_started,
  profile_edit_completed,
  business_card_created,
  business_card_updated,
  tab_switched,
  content_customized,
}

extension EventTypeExtension on EventType {
  String get value {
    switch (this) {
      case EventType.dwell:
        return 'dwell';
      case EventType.like:
        return 'like';
      case EventType.dislike:
        return 'dislike';
      case EventType.save:
        return 'save';
      case EventType.share:
        return 'share';
      case EventType.download:
        return 'download';
      case EventType.skip:
        return 'skip';
      case EventType.report:
        return 'report';
      case EventType.profile_edit_started:
        return 'profile_edit_started';
      case EventType.profile_edit_completed:
        return 'profile_edit_completed';
      case EventType.business_card_created:
        return 'business_card_created';
      case EventType.business_card_updated:
        return 'business_card_updated';
      case EventType.tab_switched:
        return 'tab_switched';
      case EventType.content_customized:
        return 'content_customized';
    }
  }
}

class Event {
  final int? id;
  final String? userId;
  final String? deviceId;
  final bool? isGuest;
  final EventType event;
  final String? cardId;
  final String? sessionId;
  final int? dwellMs;
  final int? position;
  final Map<String, dynamic>? context;
  final DateTime? createdAt;

  Event({
    this.id,
    this.userId,
    this.deviceId,
    this.isGuest,
    required this.event,
    this.cardId,
    this.sessionId,
    this.dwellMs,
    this.position,
    this.context,
    this.createdAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      userId: json['user_id'],
      deviceId: json['device_id'],
      isGuest: json['is_guest'],
      event: EventType.values.firstWhere(
        (e) => e.value == json['event'],
        orElse: () => EventType.dwell,
      ),
      cardId: json['card_id'],
      sessionId: json['session_id'],
      dwellMs: json['dwell_ms'],
      position: json['position'],
      context: json['context'] != null 
          ? Map<String, dynamic>.from(json['context']) 
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'device_id': deviceId,
      'is_guest': isGuest,
      'event': event.value,
      'card_id': cardId,
      'session_id': sessionId,
      'dwell_ms': dwellMs,
      'position': position,
      'context': context,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
