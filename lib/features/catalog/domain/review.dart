class Review {
  final String id;
  final int rating;
  final String? comment;
  final String userName;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.rating,
    this.comment,
    required this.userName,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'] as String,
        rating: (json['rating'] as num).toInt(),
        comment: json['comment'] as String?,
        userName: json['user_name'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'rating': rating,
        if (comment != null) 'comment': comment,
        'user_name': userName,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  String toString() => 'Review(id: $id, rating: $rating, userName: $userName)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Review && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
