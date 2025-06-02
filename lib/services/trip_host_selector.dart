import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/trip_guest_screen.dart';
import '../screens/trip_host_screen.dart';

class TripSelectorScreen extends StatelessWidget {
  const TripSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text("Not logged in."));
    }
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.data!.exists) {
          return const Center(child: Text("User profile not found."));
        }
        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final userType = userData['userType'] ?? 'guest';

        if (userType == 'host') {
          return const TripHostScreen();
        } else {
          return const TripGuestScreen();
        }
      },
    );
  }
}