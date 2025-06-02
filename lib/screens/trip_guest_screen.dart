import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:aframe_rentals/screens/user_profile_screen.dart'; // adjust import as needed
import 'package:aframe_rentals/screens/place_detail_screen.dart';

import '../models/place_model.dart'; // adjust import as needed

class TripGuestScreen extends StatefulWidget {
  const TripGuestScreen({super.key});

  @override
  State<TripGuestScreen> createState() => _TripGuestScreenState();
}

class _TripGuestScreenState extends State<TripGuestScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;
  bool loading = true;
  List<Map<String, dynamic>> reservations = [];
  int? expandedIndex;

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
    double ownerRating = 5.0;
    double placeRating = 5.0;
    TextEditingController ownerController = TextEditingController();
    TextEditingController placeController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text("Review your stay at ${booking['placeTitle']}"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Rate the owner:"),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (idx) => IconButton(
                        icon: Icon(
                          idx < ownerRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () => setDialogState(() => ownerRating = idx + 1.0),
                      )),
                    ),
                    TextField(
                      controller: ownerController,
                      decoration: const InputDecoration(
                        hintText: "Your feedback for the owner...",
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text("Rate the place:"),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (idx) => IconButton(
                        icon: Icon(
                          idx < placeRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () => setDialogState(() => placeRating = idx + 1.0),
                      )),
                    ),
                    TextField(
                      controller: placeController,
                      decoration: const InputDecoration(
                        hintText: "Your feedback for the place...",
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
                ElevatedButton(
                  child: const Text("Submit"),
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser!;
                    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                    final userName = userDoc['name'] ?? '';
                    final userPic = userDoc['photoUrl'] ?? '';

                    // 1. Review for the owner
                    await FirebaseFirestore.instance.collection('reviews').add({
                      'placeId': booking['placeId'],
                      'userId': user.uid,
                      'userName': userName,
                      'userProfilePic': userPic,
                      'comment': ownerController.text.trim(),
                      'rating': ownerRating,
                      'timestamp': DateTime.now().toIso8601String(),
                      'targetUserId': booking['ownerId'],
                      'type': 'owner',
                    });

                    // 2. Review for the place
                    await FirebaseFirestore.instance.collection('reviews').add({
                      'placeId': booking['placeId'],
                      'userId': user.uid,
                      'userName': userName,
                      'userProfilePic': userPic,
                      'comment': placeController.text.trim(),
                      'rating': placeRating,
                      'timestamp': DateTime.now().toIso8601String(),
                      'targetUserId': booking['placeId'],
                      'type': 'place',
                    });

                    Navigator.of(ctx).pop();
                    await loadData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Review submitted!")),
                      );
                    }
                  },
                )
              ],
            );
          },
        );
      },
    );
  }

  Widget bookingCard(Map<String, dynamic> res, int idx) {
    final start = DateFormat('yMMMd').format(DateTime.parse(res['startDate']));
    final end = DateFormat('yMMMd').format(DateTime.parse(res['endDate']));
    final isExpanded = expandedIndex == idx;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 7),
      child: ExpansionTile(
        initiallyExpanded: isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            expandedIndex = expanded ? idx : null;
          });
        },
        leading: res['placeImage'] != null && res['placeImage'].toString().isNotEmpty
            ? ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(res['placeImage'], width: 44, height: 44, fit: BoxFit.cover),
        )
            : const Icon(Icons.home, size: 40),
        title: Text(res['placeTitle'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.blue.shade50,
                ),
                child: Text("From: $start", overflow: TextOverflow.ellipsis),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.green.shade50,
                ),
                child: Text("To: $end", overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
        ),
        children: [
          // Host profile summary with tap
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(res['ownerId']).get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox.shrink();
                  }
                  var data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => UserProfileScreen(userId: res['ownerId']),
                      ));
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: (data['photoUrl'] != null && data['photoUrl'].toString().isNotEmpty)
                              ? NetworkImage(data['photoUrl'])
                              : null,
                          backgroundColor: Colors.grey.shade300,
                          radius: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            data['name'] ?? 'Host',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  );
                }
            ),
          ),
          // Place info section (simple version)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (res['placeImage'] != null && res['placeImage'].toString().isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(res['placeImage'], height: 140, width: double.infinity, fit: BoxFit.cover),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      res['placeAddress'] ?? '',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    const Icon(Icons.attach_money, size: 18),
                    Text(res['price'] != null ? '${res['price']}' : '', style: const TextStyle(fontSize: 15)),
                  ],
                ),
                if (res['placeDescription'] != null && res['placeDescription'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(res['placeDescription'], style: const TextStyle(fontSize: 14)),
                  ),
                const SizedBox(height: 4),
                TextButton(
                  child: const Text('View Place Details'),
                  onPressed: () async {
                    final placeId = res['placeId'];
                    if (placeId != null) {
                      // Fetch place document from Firestore
                      final doc = await FirebaseFirestore.instance.collection('places').doc(placeId).get();
                      if (doc.exists) {
                        final placeData = doc.data();
                        if (placeData != null) {
                          // Assuming you have Place.fromJson or Place.fromFirestore
                          final place = Place.fromJson({...placeData, 'id': placeId});
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlaceDetailScreen(place: place),
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
                const SizedBox(height: 4),
                ElevatedButton(
                  child: const Text("Review"),
                  onPressed: () => showGuestReviewDialog(res),
                ),
              ],
            ),
          ),
        ],
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
            : ListView.builder(
          itemCount: reservations.length,
          itemBuilder: (context, idx) => bookingCard(reservations[idx], idx),
        ),
      ),
    );
  }
}
