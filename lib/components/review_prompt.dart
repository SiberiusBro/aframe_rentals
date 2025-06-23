import 'package:aframe_rentals/models/place_model.dart';
// NOU: Nu mai avem nevoie de modelul Review aici, vom construi direct un Map.
// import 'package:aframe_rentals/models/review_model.dart';
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
  // NOU: Adăugăm o stare pentru a dezactiva butonul în timpul trimiterii.
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _checkIfCanReview();
  }

  Future<void> _checkIfCanReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Verifică dacă utilizatorul a lăsat deja o recenzie pentru acest loc.
    final reviews = await FirebaseFirestore.instance
        .collection('reviews')
        .where('userId', isEqualTo: user.uid)
        .where('placeId', isEqualTo: widget.place.id)
        .limit(1) // Eficiență: ne trebuie doar să știm dacă există cel puțin una.
        .get();

    if (reviews.docs.isNotEmpty) return; // Dacă a lăsat deja, nu afișăm prompt-ul.

    // Verifică dacă utilizatorul a avut o rezervare finalizată.
    // MODIFICAT: Asigură-te că numele colecției este corect ('bookings' sau 'reservations')
    final reservations = await FirebaseFirestore.instance
        .collection('bookings') // SAU 'reservations', verifică numele corect în baza ta de date!
        .where('userId', isEqualTo: user.uid)
        .where('placeId', isEqualTo: widget.place.id)
        .get();

    for (var doc in reservations.docs) {
      final endDateString = doc.get('endDate') as String?;
      if (endDateString != null) {
        final endDate = DateTime.tryParse(endDateString);
        // Afișăm prompt-ul doar dacă rezervarea s-a încheiat.
        if (endDate != null && DateTime.now().isAfter(endDate)) {
          if (mounted) {
            setState(() => _shouldShow = true);
          }
          break; // Am găsit o rezervare validă, ieșim din buclă.
        }
      }
    }
  }
  // MODIFICAT: Funcția _submitReview a fost complet rescrisă pentru a folosi o tranzacție.
  Future<void> _submitReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    final placeId = widget.place.id!;

    // Referințe către documente
    final placeRef = FirebaseFirestore.instance.collection('places').doc(placeId);
    final reviewRef = FirebaseFirestore.instance.collection('reviews').doc(); // Un ID nou pentru recenzie

    try {
      // Rulează întreaga operațiune într-o tranzacție atomică.
      // Asta înseamnă că fie toți pașii reușesc, fie niciunul.
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Pasul 1: Obține datele actuale ale locației ÎN interiorul tranzacției.
        final placeSnapshot = await transaction.get(placeRef);

        if (!placeSnapshot.exists) {
          throw Exception("Locația nu mai există!");
        }

        // Pasul 2: Calculează noul rating mediu.
        final currentRating = (placeSnapshot.data()!['rating'] as num?)?.toDouble() ?? 0.0;
        final currentReviewCount = (placeSnapshot.data()!['reviewCount'] as int?) ?? 0;

        final newTotalRatingPoints = (currentRating * currentReviewCount) + _rating;
        final newReviewCount = currentReviewCount + 1;
        final newAverageRating = newTotalRatingPoints / newReviewCount;

        // Pasul 3: Pregătește datele pentru noua recenzie.
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final newReviewData = {
          'placeId': placeId,
          'userId': user.uid,
          'userName': userDoc.data()?['name'] ?? 'Utilizator Anonim',
          'userProfilePic': userDoc.data()?['photoUrl'],
          'comment': _controller.text.trim(),
          'rating': _rating,
          'timestamp': FieldValue.serverTimestamp(), // Folosim timestamp-ul serverului pentru consistență.
          'type': 'place',
          'targetUserId': widget.place.vendor,
        };

        // Pasul 4: Actualizează locația și adaugă recenzia.
        transaction.update(placeRef, {
          'rating': newAverageRating,
          'reviewCount': newReviewCount, // Bonus: salvăm și numărul total de recenzii.
        });

        transaction.set(reviewRef, newReviewData);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Mulțumim pentru recenzie!"))
        );
        setState(() => _shouldShow = false);
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Eroare la trimiterea recenziei: $e"))
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
              const Text("Lasă o recenzie", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              StarRating(rating: _rating, onChanged: (val) => setState(() => _rating = val)),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                decoration: const InputDecoration(hintText: "Experiența ta..."),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  // MODIFICAT: Dezactivăm butonul dacă se trimite deja recenzia.
                  onPressed: _isSubmitting ? null : _submitReview,
                  child: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Trimite"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
