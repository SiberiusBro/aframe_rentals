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
    required int age,
    required String gender,
    File? imageFile,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    String? imageUrl;

    if (imageFile != null) {
      final ref = FirebaseStorage.instance.ref().child('user_avatars/$uid.jpg');
      await ref.putFile(imageFile);
      imageUrl = await ref.getDownloadURL();

      // 🔥 Update FirebaseAuth photoURL
      await FirebaseAuth.instance.currentUser!.updatePhotoURL(imageUrl);
    }

    // 🔥 Update FirebaseAuth displayName
    await FirebaseAuth.instance.currentUser!.updateDisplayName(name);

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'name': name,
      'age': age,
      'gender': gender,
      'photoUrl': imageUrl ?? FirebaseAuth.instance.currentUser!.photoURL,
    }, SetOptions(merge: true));
  }


  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data();
  }
}
