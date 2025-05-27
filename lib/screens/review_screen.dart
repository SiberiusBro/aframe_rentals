import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/place_model.dart';

class ReviewScreen extends StatefulWidget {
  final Place place;
  const ReviewScreen({super.key, required this.place});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final commentController = TextEditingController();
  double rating = 3.0;
  bool isSubmitting = false;

  Future<void> submitReview() async {
    setState(() => isSubmitting = true);

    final user = FirebaseAuth.instance.currentUser!;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    final existing = await FirebaseFirestore.instance
        .collection('reviews')
        .where('userId', isEqualTo: user.uid)
        .where('placeId', isEqualTo: widget.place.id)
        .get();

    if (existing.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You already reviewed this place.")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('reviews').add({
      'userId': user.uid,
      'userName': userDoc['name'],
      'userProfilePic': userDoc['profileImage'],
      'placeId': widget.place.id,
      'comment': commentController.text.trim(),
      'rating': rating,
      'timestamp': DateTime.now().toIso8601String(),
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Leave a Review")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("How was your stay at ${widget.place.title}?"),
            const SizedBox(height: 16),
            Slider(
              min: 1,
              max: 5,
              divisions: 4,
              value: rating,
              label: rating.toString(),
              onChanged: (val) => setState(() => rating = val),
            ),
            TextField(
              controller: commentController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: "Write your experience...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isSubmitting ? null : submitReview,
              child: isSubmitting
                  ? const CircularProgressIndicator()
                  : const Text("Submit Review"),
            )
          ],
        ),
      ),
    );
  }
}