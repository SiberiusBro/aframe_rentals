import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

Future<void> showGuestDualReviewDialog(BuildContext context, Map<String, dynamic> booking) async {
  double placeRating = 5.0;
  double hostRating = 5.0;
  final placeCommentController = TextEditingController();
  final hostCommentController = TextEditingController();
  bool submitting = false;

  await showDialog(
      context: context,
      barrierDismissible: !submitting,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text("Review the Location ${booking['placeTitle']}"),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Despre Locație", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: List.generate(5, (i) => IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        i < placeRating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                      ),
                      onPressed: () => setState(() => placeRating = (i + 1).toDouble()),
                    )),
                  ),
                  TextField(
                    controller: placeCommentController,
                    decoration: const InputDecoration(hintText: "Comentariul tău despre locație..."),
                    minLines: 1,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  Text("Despre Gazdă: ${booking['ownerName'] ?? ''}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: List.generate(5, (i) => IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        i < hostRating ? Icons.star : Icons.star_border,
                        color: Colors.blue,
                      ),
                      onPressed: () => setState(() => hostRating = (i + 1).toDouble()),
                    )),
                  ),
                  TextField(
                    controller: hostCommentController,
                    decoration: const InputDecoration(hintText: "Comentariul tău despre gazdă..."),
                    minLines: 1,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text("Anulează"),
                onPressed: submitting ? null : () => Navigator.of(context).pop(),
              ),
              ElevatedButton(
                child: submitting
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text("Trimite"),
                onPressed: submitting ? null : () async {
                  setState(() => submitting = true);

                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) {
                    setState(() => submitting = false);
                    return;
                  }

                  final placeId = booking['placeId'];
                  final hostId = booking['ownerId'];

                  final placeRef = FirebaseFirestore.instance.collection('places').doc(placeId);
                  final placeReviewRef = FirebaseFirestore.instance.collection('reviews').doc();
                  final hostReviewRef = FirebaseFirestore.instance.collection('host_reviews').doc();

                  try {
                    await FirebaseFirestore.instance.runTransaction((transaction) async {
                      final placeSnapshot = await transaction.get(placeRef);
                      if (!placeSnapshot.exists) throw Exception("Locația nu a fost găsită.");

                      final currentRating = (placeSnapshot.data()?['rating'] as num?)?.toDouble() ?? 0.0;
                      final currentReviewCount = (placeSnapshot.data()?['reviewCount'] as int?) ?? 0;

                      final newTotalRatingPoints = (currentRating * currentReviewCount) + placeRating;
                      final newReviewCount = currentReviewCount + 1;
                      final newAverageRating = newTotalRatingPoints / newReviewCount;

                      final placeReviewData = {
                        'placeId': placeId,
                        'userId': user.uid,
                        'userName': booking['userName'],
                        'userProfilePic': booking['userProfile'],
                        'comment': placeCommentController.text.trim(),
                        'rating': placeRating,
                        'timestamp': FieldValue.serverTimestamp(),
                        'type': 'place',
                      };

                      final hostReviewData = {
                        'hostId': hostId,
                        'guestId': user.uid,
                        'guestName': booking['userName'],
                        'guestProfilePic': booking['userProfile'],
                        'comment': hostCommentController.text.trim(),
                        'rating': hostRating,
                        'timestamp': FieldValue.serverTimestamp(),
                        'type': 'host',
                        'placeId': placeId,
                        'reservationId': booking['reservationId'],
                      };

                      transaction.update(placeRef, {
                        'rating': newAverageRating,
                        'reviewCount': newReviewCount,
                      });
                      transaction.set(placeReviewRef, placeReviewData);
                      transaction.set(hostReviewRef, hostReviewData);
                    });

                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Recenzie trimisă cu succes!")),
                      );
                    }

                  } catch (e) {
                    // Pasul 5: Feedback de eroare
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("A apărut o eroare: $e")),
                      );
                    }
                  } finally {
                    if (context.mounted) {
                      setState(() => submitting = false);
                    }
                  }
                },
              )
            ],
          );
        });
      }
  );
}
