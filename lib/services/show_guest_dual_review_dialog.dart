import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<void> showGuestDualReviewDialog(BuildContext context, Map<String, dynamic> booking) async {
  double placeRating = 5.0;
  double hostRating = 5.0;
  final placeCommentController = TextEditingController();
  final hostCommentController = TextEditingController();
  bool submitting = false;

  await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text("Review Stay at ${booking['placeTitle']}"),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Place Review ---
                  const Text("Place", style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: List.generate(5, (i) => IconButton(
                      icon: Icon(
                        i < placeRating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                      ),
                      onPressed: () => setState(() => placeRating = (i + 1).toDouble()),
                    )),
                  ),
                  TextField(
                    controller: placeCommentController,
                    decoration: const InputDecoration(hintText: "Comment about the place..."),
                    minLines: 1, maxLines: 3,
                  ),
                  const SizedBox(height: 14),
                  // --- Host Review ---
                  Text("Host: ${booking['ownerName'] ?? ''}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: List.generate(5, (i) => IconButton(
                      icon: Icon(
                        i < hostRating ? Icons.star : Icons.star_border,
                        color: Colors.blue,
                      ),
                      onPressed: () => setState(() => hostRating = (i + 1).toDouble()),
                    )),
                  ),
                  TextField(
                    controller: hostCommentController,
                    decoration: const InputDecoration(hintText: "Comment about the host..."),
                    minLines: 1, maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.of(context).pop(),
              ),
              ElevatedButton(
                child: submitting ? const SizedBox(height:18, width:18, child:CircularProgressIndicator(strokeWidth:2)) : const Text("Submit"),
                onPressed: submitting ? null : () async {
                  setState(() => submitting = true);
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) return;

                  // Save PLACE review
                  await FirebaseFirestore.instance.collection('reviews').add({
                    'placeId': booking['placeId'],
                    'userId': user.uid,
                    'userName': booking['userName'],
                    'userProfilePic': booking['userProfile'],
                    'comment': placeCommentController.text.trim(),
                    'rating': placeRating,
                    'timestamp': DateTime.now().toIso8601String(),
                    'type': 'place',
                  });
                  // Save HOST review
                  await FirebaseFirestore.instance.collection('host_reviews').add({
                    'hostId': booking['ownerId'],
                    'guestId': user.uid,
                    'guestName': booking['userName'],
                    'guestProfilePic': booking['userProfile'],
                    'comment': hostCommentController.text.trim(),
                    'rating': hostRating,
                    'timestamp': DateTime.now().toIso8601String(),
                    'type': 'host',
                    'placeId': booking['placeId'],
                    'reservationId': booking['reservationId'],
                  });

                  setState(() => submitting = false);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Review submitted!")),
                  );
                },
              )
            ],
          );
        });
      }
  );
}
