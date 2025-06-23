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

  // MODIFICAT: Funcția submitReview a fost complet rescrisă.
  Future<void> submitReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || isSubmitting) return;

    setState(() => isSubmitting = true);

    // Verifică dacă utilizatorul a lăsat deja o recenzie.
    final existingReviews = await FirebaseFirestore.instance
        .collection('reviews')
        .where('userId', isEqualTo: user.uid)
        .where('placeId', isEqualTo: widget.place.id)
        .limit(1)
        .get();

    if (existingReviews.docs.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ați lăsat deja o recenzie pentru această locație.")),
        );
      }
      setState(() => isSubmitting = false);
      return;
    }

    final placeId = widget.place.id!;
    final placeRef = FirebaseFirestore.instance.collection('places').doc(placeId);
    final reviewRef = FirebaseFirestore.instance.collection('reviews').doc();

    try {
      // NOU: Folosim o tranzacție pentru a asigura consistența datelor.
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Pasul 1: Obține datele actuale ale locației.
        final placeSnapshot = await transaction.get(placeRef);
        if (!placeSnapshot.exists) {
          throw Exception("Locația nu a fost găsită.");
        }

        // Pasul 2: Calculează noul rating mediu.
        final currentRating = (placeSnapshot.data()?['rating'] as num?)?.toDouble() ?? 0.0;
        final currentReviewCount = (placeSnapshot.data()?['reviewCount'] as int?) ?? 0;

        final newTotalRatingPoints = (currentRating * currentReviewCount) + rating;
        final newReviewCount = currentReviewCount + 1;
        final newAverageRating = newTotalRatingPoints / newReviewCount;

        // Pasul 3: Obține datele utilizatorului pentru recenzie.
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final newReviewData = {
          'userId': user.uid,
          'userName': userDoc.data()?['name'] ?? 'Utilizator Anonim',
          'userProfilePic': userDoc.data()?['profileImage'], // Verifică dacă acest câmp este 'photoUrl' sau 'profileImage'
          'placeId': placeId,
          'comment': commentController.text.trim(),
          'rating': rating,
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'place'
        };

        // Pasul 4: Actualizează locația și adaugă recenzia în aceeași operațiune.
        transaction.update(placeRef, {
          'rating': newAverageRating,
          'reviewCount': newReviewCount,
        });
        transaction.set(reviewRef, newReviewData);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Recenzie trimisă cu succes!"))
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Eroare: $e"))
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Lasă o recenzie")),
      body: SingleChildScrollView( // NOU: Adăugat pentru a preveni overflow-ul pe ecrane mici
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // NOU: Pentru a alinia mai bine elementele
            children: [
              Text(
                "Cum a fost șederea la ${widget.place.title}?",
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Center(
                  child: Text(
                    rating.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Theme.of(context).primaryColor),
                  )
              ),
              Slider(
                min: 1,
                max: 5,
                divisions: 4,
                value: rating,
                label: rating.toStringAsFixed(1),
                onChanged: (val) => setState(() => rating = val),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: "Descrie experiența ta...",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.black12,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: isSubmitting ? null : submitReview,
                child: isSubmitting
                    ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                )
                    : const Text("Trimite Recenzia"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
