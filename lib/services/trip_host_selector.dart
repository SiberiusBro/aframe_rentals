import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../screens/trip_guest_screen.dart';
import '../screens/trip_host_screen.dart';

class TripSelectorScreen extends StatelessWidget {
  const TripSelectorScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('places')
          .where('vendor', isEqualTo: currentUser!.uid)
          .get(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final isHost = snap.data!.docs.isNotEmpty;
        if (isHost) {
          return const TripHostScreen();
        } else {
          return const TripGuestScreen();
        }
      },
    );
  }
}
