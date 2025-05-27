import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'booking_request_detail_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("Not logged in")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reservations')
            .where('ownerId', isEqualTo: currentUser.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final reservations = snapshot.data!.docs;

          if (reservations.isEmpty) {
            return const Center(child: Text("No notifications yet."));
          }

          return ListView.builder(
            itemCount: reservations.length,
            itemBuilder: (context, index) {
              final data = reservations[index].data() as Map<String, dynamic>;
              final docId = reservations[index].id;

              final name = data['userName'] ?? "Someone";
              final placeTitle = data['placeTitle'] ?? "a place";
              final startDate = DateFormat('yMMMd').format(DateTime.parse(data['startDate']));
              final endDate = DateFormat('yMMMd').format(DateTime.parse(data['endDate']));
              final requesterId = data['userId'];
              final status = data['status'] ?? 'pending';

              return ListTile(
                leading: Icon(
                  status == 'accepted'
                      ? Icons.check_circle
                      : status == 'declined'
                      ? Icons.cancel
                      : Icons.notifications_active_outlined,
                  color: status == 'accepted'
                      ? Colors.green
                      : status == 'declined'
                      ? Colors.red
                      : Colors.blue,
                ),
                title: Text("$name wants to book $placeTitle"),
                subtitle: Text(
                  "$startDate → $endDate\nStatus: ${status[0].toUpperCase()}${status.substring(1)}",
                ),
                isThreeLine: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingRequestDetailScreen(
                        reservationId: docId,
                        requesterId: requesterId,
                        reservationData: data,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
