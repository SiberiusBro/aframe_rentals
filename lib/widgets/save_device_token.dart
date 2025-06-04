//widgets/save_device_token.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class DeviceTokenService {
  static Future<void> saveTokenToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);

    await userDoc.set({
      'deviceToken': token,
    }, SetOptions(merge: true));
  }
}
