import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TripGuestScreen extends StatefulWidget {
  const TripGuestScreen({super.key});

  @override
  State<TripGuestScreen> createState() => _TripGuestScreenState();
}

class _TripGuestScreenState extends State<TripGuestScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;
  bool loading = true;
  List<Map<String, dynamic>> reservations = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final uid = currentUser!.uid;
    final resSnap = await FirebaseFirestore.instance
        .collection('reservations')
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: 'accepted')
        .orderBy('startDate', descending: false)
        .get();
    setState(() {
      reservations = resSnap.docs.map((doc) => {...doc.data(), 'reservationId': doc.id}).toList();
      loading = false;
    });
  }

  Future<void> showGuestReviewDialog(Map<String, dynamic> booking) async {
    double _rating = 5.0;
    TextEditingController controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Review your stay at ${booking['placeTitle']}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                min: 1,
                max: 5,
                divisions: 4,
                value: _rating,
                label: _rating.toString(),
                onChanged: (v) => setState(() => _rating = v),
              ),
              TextField(
                controller: controller,
                decoration: const InputDecoration(hintText: "Your feedback..."),
              )
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text("Submit"),
              onPressed: () async {
                // Fetch guest's user data
                final user = FirebaseAuth.instance.currentUser!;
                final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                final userName = userDoc['name'] ?? '';
                final userPic = userDoc['photoUrl'] ?? '';

                // Review goes to HOST's profile for this stay
                await FirebaseFirestore.instance.collection('reviews').add({
                  'placeId': booking['placeId'],
                  'userId': user.uid,
                  'userName': userName,
                  'userProfilePic': userPic,
                  'comment': controller.text.trim(),
                  'rating': _rating,
                  'timestamp': DateTime.now().toIso8601String(),
                  'targetUserId': booking['ownerId'], // The host UID!
                });
                Navigator.of(context).pop();
                await loadData();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Review submitted!")));
              },
            )
          ],
        );
      },
    );
  }

  Widget bookingCard(Map<String, dynamic> res) {
    final start = DateFormat('yMMMd').format(DateTime.parse(res['startDate']));
    final end = DateFormat('yMMMd').format(DateTime.parse(res['endDate']));
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 7),
      child: ListTile(
        leading: res['placeImage'] != null && res['placeImage'].toString().isNotEmpty
            ? ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(res['placeImage'], width: 44, height: 44, fit: BoxFit.cover),
        )
            : const Icon(Icons.home, size: 40),
        title: Text(res['placeTitle'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Host: ${res['ownerName'] ?? '-'}"),
            const SizedBox(height: 3),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.blue.shade50,
                  ),
                  child: Text("From: $start"),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.green.shade50,
                  ),
                  child: Text("To: $end"),
                ),
              ],
            ),
          ],
        ),
        trailing: ElevatedButton(
          child: const Text("Review"),
          onPressed: () => showGuestReviewDialog(res),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      appBar: AppBar(title: const Text("My Trips")),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: reservations.isEmpty
            ? const Center(child: Text("No trips found."))
            : ListView(
          children: reservations.map(bookingCard).toList(),
        ),
      ),
    );
  }
}
