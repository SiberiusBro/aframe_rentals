//screens/booking_request_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'chat_screen.dart'; // <-- import your chat screen here

class BookingRequestDetailScreen extends StatefulWidget {
  final String reservationId;
  final String requesterId;
  final Map<String, dynamic> reservationData;

  const BookingRequestDetailScreen({
    super.key,
    required this.reservationId,
    required this.requesterId,
    required this.reservationData,
  });

  @override
  State<BookingRequestDetailScreen> createState() => _BookingRequestDetailScreenState();
}

class _BookingRequestDetailScreenState extends State<BookingRequestDetailScreen> {
  Map<String, dynamic>? requesterProfile;

  @override
  void initState() {
    super.initState();
    _loadRequesterProfile();
  }

  Future<void> _loadRequesterProfile() async {
    final userSnap = await FirebaseFirestore.instance.collection('users').doc(widget.requesterId).get();
    if (userSnap.exists) {
      setState(() {
        requesterProfile = userSnap.data();
      });
    }
  }

  Future<void> _updateReservationStatus(String status) async {
    await FirebaseFirestore.instance
        .collection('reservations')
        .doc(widget.reservationId)
        .update({'status': status});

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reservation $status')));
  }

  @override
  Widget build(BuildContext context) {
    final res = widget.reservationData;
    final startDateFormatted = DateFormat('yMMMd').format(DateTime.parse(res['startDate']));
    final endDateFormatted = DateFormat('yMMMd').format(DateTime.parse(res['endDate']));
    final status = res['status'] ?? 'pending';

    return Scaffold(
      appBar: AppBar(title: const Text("Booking Request")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              "Place: ${res['placeTitle']}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text("Requested by: ${res['userName']}"),
            if (requesterProfile != null) ...[
              Text("User Email: ${requesterProfile!['email'] ?? '-'}"),
              // Add any other user info you want here
              const SizedBox(height: 8),
            ],
            Text("From: $startDateFormatted"),
            Text("To: $endDateFormatted"),
            Text(
              "Status: ${status[0].toUpperCase()}${status.substring(1)}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: status == 'accepted'
                    ? Colors.green
                    : status == 'declined'
                    ? Colors.red
                    : Colors.orange,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.chat),
                  label: const Text("Chat"),
                  onPressed: () {
                    final placeId = widget.reservationData['placeId'];
                    final userId = widget.requesterId;

                    // Debug log: print values to console
                    debugPrint('Chat button pressed. placeId: $placeId, userId: $userId');

                    if (placeId == null || placeId is! String || placeId.isEmpty ||
                        userId == null || userId is! String || userId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Chat information is missing or invalid.")),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          otherUserId: userId,
                          placeId: placeId,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                if (status == 'pending') ...[
                  ElevatedButton(
                    child: const Text("Accept"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () => _updateReservationStatus('accepted'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    child: const Text("Decline"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () => _updateReservationStatus('declined'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
