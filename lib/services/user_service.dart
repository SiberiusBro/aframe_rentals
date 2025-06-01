//services/user_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> saveUserProfile({
    required String name,
    required String gender,
    required DateTime birthdate,
    required String userType,
    String? description,
    File? imageFile,
  }) async {
    final uid = _auth.currentUser!.uid;
    String? imageUrl = _auth.currentUser!.photoURL;

    // 1) Upload avatar if provided:
    if (imageFile != null) {
      final ref = _storage.ref().child('user_avatars/$uid.jpg');
      await ref.putFile(imageFile);
      imageUrl = await ref.getDownloadURL();
      await _auth.currentUser!.updatePhotoURL(imageUrl);
    }

    await _auth.currentUser!.updateDisplayName(name);

    await _firestore.collection('users').doc(uid).set({
      'name': name,
      'gender': gender,
      'birthdate': Timestamp.fromDate(birthdate),
      'description': description ?? '',
      'userType': userType,
      'photoUrl': imageUrl,
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data();
  }

  Future<Map<String, dynamic>?> getUserProfileById(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }
}
