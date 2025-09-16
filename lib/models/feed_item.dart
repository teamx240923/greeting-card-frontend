import 'card.dart';

class FeedItem {
  final int id;
  final int rank;
  final Card? card;
  final double? recScore;
  final String? reason;

  FeedItem({
    required this.id,
    required this.rank,
    this.card,
    this.recScore,
    this.reason,
  });

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    return FeedItem(
      id: json['id'],
      rank: json['rank'],
      card: json['card'] != null ? Card.fromJson(json['card']) : null,
      recScore: json['rec_score']?.toDouble(),
      reason: json['reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rank': rank,
      'card': card?.toJson(),
      'rec_score': recScore,
      'reason': reason,
    };
  }
}
