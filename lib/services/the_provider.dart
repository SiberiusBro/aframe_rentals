//services/the_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TheProvider extends ChangeNotifier {
  List<String> _favoriteIds = [];
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  List<String> get favorites => _favoriteIds;

  TheProvider() {
    if (FirebaseAuth.instance.currentUser != null) {
      loadFavorite();
    }
  }

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

  Future<void> toggleFavorite(DocumentSnapshot place) async {
    await toggleFavoriteById(place.id);
  }

  bool isFavorite(String placeId) {
    return _favoriteIds.contains(placeId);
  }

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

  static TheProvider of(BuildContext context, {bool listen = true}) {
    return Provider.of<TheProvider>(context, listen: listen);
  }
}
