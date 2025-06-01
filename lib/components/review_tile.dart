//components/review_title.dart
import 'package:flutter/material.dart';
import 'star_rating.dart';
import 'package:intl/intl.dart';

class ReviewTile extends StatelessWidget {
  final String userName;
  final String comment;
  final double rating;
  final DateTime timestamp;

  const ReviewTile({
    super.key,
    required this.userName,
    required this.comment,
    required this.rating,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      leading: const CircleAvatar(
        radius: 22,
        backgroundColor: Colors.black12,
        child: Icon(Icons.person, color: Colors.black),
      ),
      title: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StarRating(rating: rating),
          const SizedBox(height: 4),
          Text(comment),
          Text(
            DateFormat('yMMMd').format(timestamp),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
