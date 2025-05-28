import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TheProvider extends ChangeNotifier {
  // Favorite place IDs for the current user
  List<String> _favoriteIds = [];
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  List<String> get favorites => _favoriteIds;

  TheProvider() {
    // Load favorites for the current user (if any)
    if (FirebaseAuth.instance.currentUser != null) {
      loadFavorite();
    }
  }

  // Toggle a place's favorite state for the current user
  Future<void> toggleFavoriteById(String placeId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      if (_favoriteIds.contains(placeId)) {
        _favoriteIds.remove(placeId);
        // Remove from user's favorites in Firestore
        await firebaseFirestore
            .collection("userFavorites")
            .doc(user.uid)
            .collection("favorites")
            .doc(placeId)
            .delete();
      } else {
        _favoriteIds.add(placeId);
        // Add to user's favorites in Firestore
        await firebaseFirestore
            .collection("userFavorites")
            .doc(user.uid)
            .collection("favorites")
            .doc(placeId)
            .set({'isFavorite': true});
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error toggling favorite: ${e.toString()}");
      }
    }
    notifyListeners();
  }

  // (Optional) Toggle favorites using a DocumentSnapshot (for compatibility)
  Future<void> toggleFavorite(DocumentSnapshot place) async {
    await toggleFavoriteById(place.id);
  }

  // Check if a place is favorited by the current user
  bool isFavorite(String placeId) {
    return _favoriteIds.contains(placeId);
  }

  // Load favorite place IDs for the current user from Firestore
  Future<void> loadFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _favoriteIds = [];
      notifyListeners();
      return;
    }
    try {
      final snapshot = await firebaseFirestore
          .collection("userFavorites")
          .doc(user.uid)
          .collection("favorites")
          .get();
      _favoriteIds = snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      if (kDebugMode) {
        print("Error loading favorites: ${e.toString()}");
      }
    }
    notifyListeners();
  }

  // Static helper to easily access the provider
  static TheProvider of(BuildContext context, {bool listen = true}) {
    return Provider.of<TheProvider>(context, listen: listen);
  }
}
