//screens/notifications_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'booking_request_detail_screen.dart';
import 'chat_screen.dart';

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
    final uid = currentUser.uid;
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reservations')
            .where('ownerId', isEqualTo: uid)
            .where('status', isEqualTo: 'pending')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, hostSnapshot) {
          if (!hostSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final hostReservations = hostSnapshot.data!.docs;
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('reservations')
                .where('userId', isEqualTo: uid)
                .where('status', whereIn: ['accepted', 'declined'])
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, guestSnapshot) {
              if (!guestSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final guestReservations = guestSnapshot.data!.docs;
              if (hostReservations.isEmpty && guestReservations.isEmpty) {
                return const Center(child: Text("No notifications yet."));
              }
              // Build combined list of notifications
              List<Widget> notificationWidgets = [];
              if (hostReservations.isNotEmpty) {
                notificationWidgets.add(
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "Booking Requests",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
                for (var doc in hostReservations) {
                  final data = doc.data() as Map<String, dynamic>;
                  final docId = doc.id;
                  final name = data['userName'] ?? "Someone";
                  final placeTitle = data['placeTitle'] ?? "a place";
                  final startDate = DateFormat('yMMMd').format(DateTime.parse(data['startDate']));
                  final endDate = DateFormat('yMMMd').format(DateTime.parse(data['endDate']));
                  final requesterId = data['userId'];
                  final status = data['status'] ?? 'pending';
                  notificationWidgets.add(
                    ListTile(
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
                          "$startDate → $endDate\nStatus: ${status[0].toUpperCase()}${status.substring(1)}"
                              "${status == 'declined' && data['declineReason'] != null ? "\nDecline Reason: ${data['declineReason']}" : ""}"
                              "${status == 'declined' && data['declineDescription'] != null && data['declineDescription'].toString().isNotEmpty ? "\nMore info: ${data['declineDescription']}" : ""}"
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
                    ),
                  );
                }
              }
              if (guestReservations.isNotEmpty) {
                notificationWidgets.add(
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "Booking Updates",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
                for (var doc in guestReservations) {
                  final data = doc.data() as Map<String, dynamic>;
                  final placeTitle = data['placeTitle'] ?? "a place";
                  final startDate = DateFormat('yMMMd').format(DateTime.parse(data['startDate']));
                  final endDate = DateFormat('yMMMd').format(DateTime.parse(data['endDate']));
                  final ownerId = data['ownerId'];
                  final status = data['status'] ?? '';
                  final iconData = status == 'accepted' ? Icons.check_circle : Icons.cancel;
                  final iconColor = status == 'accepted' ? Colors.green : Colors.red;
                  notificationWidgets.add(
                    ListTile(
                      leading: Icon(iconData, color: iconColor),
                      title: Text(placeTitle),
                      subtitle: Text("$startDate → $endDate\nStatus: ${status[0].toUpperCase()}${status.substring(1)}"),
                      isThreeLine: true,
                      onTap: () {
                        if ((data['status'] ?? '') == 'accepted') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(otherUserId: ownerId, placeId: data['placeId']),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookingRequestDetailScreen(
                                reservationId: doc.id,
                                requesterId: uid,
                                reservationData: data,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  );
                }
              }
              return ListView(children: notificationWidgets);
            },
          );
        },
      ),
    );
  }
}
