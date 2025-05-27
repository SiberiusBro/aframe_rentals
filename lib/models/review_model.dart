
class Review {
  final String? id; // ✅ Optional
  final String placeId;
  final String userId;
  final String userName;
  final String? userProfilePic; // ✅ Optional
  final String comment;
  final double rating;
  final DateTime timestamp;

  Review({
    this.id,
    required this.placeId,
    required this.userId,
    required this.userName,
    this.userProfilePic,
    required this.comment,
    required this.rating,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'placeId': placeId,
      'userId': userId,
      'userName': userName,
      'userProfilePic': userProfilePic,
      'comment': comment,
      'rating': rating,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Review.fromJson(Map<String, dynamic> json, {String? id}) {
    return Review(
      id: id,
      placeId: json['placeId'],
      userId: json['userId'],
      userName: json['userName'],
      userProfilePic: json['userProfilePic'],
      comment: json['comment'],
      rating: (json['rating'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}