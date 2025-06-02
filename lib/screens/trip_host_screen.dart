import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class TripHostScreen extends StatefulWidget {
  const TripHostScreen({super.key});

  @override
  State<TripHostScreen> createState() => _TripHostScreenState();
}

class _TripHostScreenState extends State<TripHostScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;
  bool loading = true;

  Map<DateTime, List<Map<String, dynamic>>> hostReservationsByDate = {};
  List<Map<String, dynamic>> reservations = [];
  Map<String, Color> guestColors = {};

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final uid = currentUser!.uid;

    // Correct: use 'userId' instead of 'ownerId'
    final places = await FirebaseFirestore.instance
        .collection('places')
        .where('userId', isEqualTo: uid)
        .get();

    List<String> myPlaceIds = places.docs.map((d) => d.id).toList();

    // Debug prints
    print('HOST UID: $uid');
    print('MY PLACE IDS: $myPlaceIds');

    if (myPlaceIds.isEmpty) {
      setState(() {
        hostReservationsByDate = {};
        guestColors = {};
        reservations = [];
        loading = false;
      });
      return;
    }

    final resSnap = await FirebaseFirestore.instance
        .collection('reservations')
        .where('placeId', whereIn: myPlaceIds)
        .where('status', isEqualTo: 'accepted')
        .get();

    Map<DateTime, List<Map<String, dynamic>>> dateMap = {};
    Map<String, Color> colorMap = {};
    final colorList = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.red,
      Colors.indigo,
      Colors.pink,
      Colors.brown,
    ];

    int colorIdx = 0;
    reservations.clear();
    for (var doc in resSnap.docs) {
      final data = doc.data();
      reservations.add({...data, 'reservationId': doc.id});
      final guestId = data['userId'];
      if (!colorMap.containsKey(guestId)) {
        colorMap[guestId] = colorList[colorIdx % colorList.length];
        colorIdx++;
      }
      DateTime start = DateTime.parse(data['startDate']);
      DateTime end = DateTime.parse(data['endDate']);
      for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
        final key = DateTime(d.year, d.month, d.day);
        dateMap.putIfAbsent(key, () => []).add({
          ...data,
          'color': colorMap[guestId]
        });
      }
    }

    print('RESERVATIONS FOUND: ${reservations.length}');

    setState(() {
      hostReservationsByDate = dateMap;
      guestColors = colorMap;
      loading = false;
    });
  }

  // ----- HOST REVIEW DIALOG (like guest popup) -----
  Future<void> showHostReviewDialog(Map<String, dynamic> guest) async {
    double guestRating = 5.0;
    TextEditingController guestController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text("Review guest ${guest['userName']}"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Rate the guest:"),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                            (idx) => IconButton(
                          icon: Icon(
                            idx < guestRating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 32,
                          ),
                          onPressed: () => setDialogState(() => guestRating = idx + 1.0),
                        ),
                      ),
                    ),
                    TextField(
                      controller: guestController,
                      decoration: const InputDecoration(
                        hintText: "Your feedback for the guest...",
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

                    // Submit the review
                    await FirebaseFirestore.instance.collection('reviews').add({
                      'placeId': guest['placeId'],
                      'userId': user.uid,
                      'userName': userName,
                      'userProfilePic': userPic,
                      'comment': guestController.text.trim(),
                      'rating': guestRating,
                      'timestamp': DateTime.now().toIso8601String(),
                      'targetUserId': guest['userId'], // Guest UID!
                      'type': 'guest', // identifies this as a guest review
                    });

                    Navigator.of(ctx).pop();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Review submitted!")),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ----- GUEST COLOR LEGEND -----
  List<Widget> buildGuestLegend() {
    return guestColors.entries.map((entry) {
      final guestId = entry.key;
      final color = entry.value;
      final guestName = reservations.firstWhere(
            (res) => res['userId'] == guestId,
        orElse: () => {},
      )['userName'] ?? '';
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.black12),
            ),
          ),
          const SizedBox(width: 6),
          Text(guestName, style: const TextStyle(fontSize: 14)),
        ],
      );
    }).toList();
  }

  // ----- GUEST CARD -----
  Widget guestInfoTile(Map<String, dynamic> res) {
    final color = guestColors[res['userId']] ?? Colors.grey;
    final guestId = res['userId'];
    final placeId = res['placeId'];

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(guestId).get(),
      builder: (context, userSnapshot) {
        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('places').doc(placeId).get(),
          builder: (context, placeSnapshot) {
            final placeData = placeSnapshot.data?.data() as Map<String, dynamic>?;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 40,
                      color: color,
                    ),
                    const SizedBox(width: 4),
                    CircleAvatar(
                      backgroundColor: color,
                      backgroundImage: (userData != null && userData['photoUrl'] != null && userData['photoUrl'].toString().isNotEmpty)
                          ? NetworkImage(userData['photoUrl'])
                          : null,
                      child: (userData == null || userData['photoUrl'] == null || userData['photoUrl'].toString().isEmpty)
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                  ],
                ),
                title: Text(userData?['name'] ?? res['userName'] ?? ''),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Place: ${placeData?['title'] ?? res['placeTitle'] ?? ''}"),
                    Text("Period: ${DateFormat('yMMMd').format(DateTime.parse(res['startDate']))} – "
                        "${DateFormat('yMMMd').format(DateTime.parse(res['endDate']))}"),
                  ],
                ),
                trailing: ElevatedButton(
                  child: const Text("Review"),
                  onPressed: () => showHostReviewDialog({
                    ...res,
                    'userName': userData?['name'] ?? res['userName'] ?? '',
                    'userProfilePic': userData?['photoUrl'] ?? '',
                  }),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      appBar: AppBar(title: const Text("Host Trip Management")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 180)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: DateTime.now(),
              calendarFormat: CalendarFormat.month,
              eventLoader: (day) {
                final key = DateTime(day.year, day.month, day.day);
                return hostReservationsByDate[key] ?? [];
              },
              calendarStyle: const CalendarStyle(
                markerDecoration: BoxDecoration(
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 4,
                markersAlignment: Alignment.bottomCenter,
              ),
              onDaySelected: (selectedDay, focusedDay) {
                // Optionally: show a dialog for this day's reservations
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isEmpty) return null;
                  // Show a little colored dot for each reservation on this day (matching guest color)
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(events.length, (idx) {
                      final ev = events[idx] as Map<String, dynamic>;
                      final color = ev['color'] as Color? ?? Colors.grey;
                      return Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.symmetric(horizontal: 0.5),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            if (guestColors.isNotEmpty) ...[
              const Text("Legend:", style: TextStyle(fontWeight: FontWeight.bold)),
              ...buildGuestLegend(),
              const SizedBox(height: 10),
            ],
            const Text("All Guests", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            if (reservations.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No reservations found.'),
              ),
            ...reservations.map(guestInfoTile).toList(),
          ],
        ),
      ),
    );
  }
}