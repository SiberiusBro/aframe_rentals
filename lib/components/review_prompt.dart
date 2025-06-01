import 'package:aframe_rentals/models/place_model.dart';
import 'package:aframe_rentals/models/review_model.dart';
import 'package:aframe_rentals/components/star_rating.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ReviewPrompt extends StatefulWidget {
  final Place place;

  const ReviewPrompt({super.key, required this.place});

  @override
  State<ReviewPrompt> createState() => _ReviewPromptState();
}

class _ReviewPromptState extends State<ReviewPrompt> {
  double _rating = 5.0;
  final _controller = TextEditingController();
  bool _shouldShow = false;

  @override
  void initState() {
    super.initState();
    _checkIfCanReview();
  }

  Future<void> _checkIfCanReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final reviews = await FirebaseFirestore.instance
        .collection('reviews')
        .where('userId', isEqualTo: user.uid)
        .where('placeId', isEqualTo: widget.place.id)
        .get();

    if (reviews.docs.isNotEmpty) return;

    final reservations = await FirebaseFirestore.instance
        .collection('reservations')
        .where('userId', isEqualTo: user.uid)
        .where('placeId', isEqualTo: widget.place.id)
        .get();

    for (var doc in reservations.docs) {
      final endDate = DateTime.parse(doc['endDate']);
      if (DateTime.now().isAfter(endDate)) {
        setState(() => _shouldShow = true);
        break;
      }
    }
  }

  Future<void> _submitReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final name = userDoc['name'] ?? 'Anonymous';
    final profilePic = userDoc['photoUrl'] ?? '';

    // Set host as targetUserId (assuming Place.vendor == host UID)
    final hostUid = widget.place.vendor; // Use .ownerId if that's the field!

    final review = Review(
      placeId: widget.place.id!,
      userId: user.uid,
      userName: name,
      userProfilePic: profilePic,
      comment: _controller.text.trim(),
      rating: _rating,
      timestamp: DateTime.now(),
      targetUserId: hostUid,
    );

    await FirebaseFirestore.instance.collection('reviews').add(review.toJson());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Thanks for your review!")));
    setState(() => _shouldShow = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Leave a Review", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              StarRating(rating: _rating, onChanged: (val) => setState(() => _rating = val)),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                decoration: const InputDecoration(hintText: "Your experience..."),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _submitReview,
                  child: const Text("Submit"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
