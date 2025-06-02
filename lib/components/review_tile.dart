// components/review_tile.dart
import 'package:flutter/material.dart';
import 'star_rating.dart';
import 'package:intl/intl.dart';

class ReviewTile extends StatelessWidget {
  final String userName;
  final String comment;
  final double rating;
  final DateTime timestamp;
  final String? userProfilePic;

  const ReviewTile({
    super.key,
    required this.userName,
    required this.comment,
    required this.rating,
    required this.timestamp,
    this.userProfilePic,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.black12,
            backgroundImage: (userProfilePic != null && userProfilePic!.isNotEmpty)
                ? NetworkImage(userProfilePic!)
                : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    StarRating(rating: rating),
                  ],
                ),
                if (comment.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(comment, style: const TextStyle(fontSize: 15)),
                ],
                const SizedBox(height: 2),
                Text(
                  DateFormat('yMMMd').format(timestamp),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
