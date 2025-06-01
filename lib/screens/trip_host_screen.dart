//screens/trip_host_screen.dart
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
    final places = await FirebaseFirestore.instance
        .collection('places')
        .where('vendor', isEqualTo: uid)
        .get();

    List<String> myPlaceIds = places.docs.map((d) => d.id).toList();

    final resSnap = await FirebaseFirestore.instance
        .collection('reservations')
        .where('placeId', whereIn: myPlaceIds.isNotEmpty ? myPlaceIds : ["DUMMY"])
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
    ];

    int colorIdx = 0;
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
    setState(() {
      hostReservationsByDate = dateMap;
      guestColors = colorMap;
      loading = false;
    });
  }

  Future<void> showHostReviewDialog(Map<String, dynamic> guest) async {
    double _rating = 5.0;
    TextEditingController controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Review ${guest['userName']}"),
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
                // Host reviewing the guest
                final user = FirebaseAuth.instance.currentUser!;
                final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                final userName = userDoc['name'] ?? '';
                final userPic = userDoc['photoUrl'] ?? '';

                await FirebaseFirestore.instance.collection('reviews').add({
                  'placeId': guest['placeId'],
                  'userId': user.uid,
                  'userName': userName,
                  'userProfilePic': userPic,
                  'comment': controller.text.trim(),
                  'rating': _rating,
                  'timestamp': DateTime.now().toIso8601String(),
                  'targetUserId': guest['userId'], // <- Guest UID!
                });
                Navigator.of(context).pop();
                // Optionally, reload data
              },
            )
          ],
        );
      },
    );
  }

  Widget guestInfoTile(Map<String, dynamic> res) {
    final color = guestColors[res['userId']] ?? Colors.grey;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: (res['userProfile'] != null && res['userProfile'].toString().isNotEmpty)
              ? ClipOval(child: Image.network(res['userProfile'], width: 36, height: 36, fit: BoxFit.cover))
              : const Icon(Icons.person, color: Colors.white),
        ),
        title: Text(res['userName'] ?? ''),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Place: ${res['placeTitle']}"),
            Text("Period: ${DateFormat('yMMMd').format(DateTime.parse(res['startDate']))} – "
                "${DateFormat('yMMMd').format(DateTime.parse(res['endDate']))}"),
          ],
        ),
        trailing: ElevatedButton(
          child: const Text("Review"),
          onPressed: () => showHostReviewDialog(res),
        ),
      ),
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
              calendarStyle: CalendarStyle(
                markerDecoration: BoxDecoration(
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 4,
                markersAlignment: Alignment.bottomCenter,
              ),
              onDaySelected: (selectedDay, focusedDay) {
                // Optionally show modal with guest details for that day
              },
            ),
            const SizedBox(height: 16),
            const Text("All Guests", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ...reservations.map(guestInfoTile).toList(),
          ],
        ),
      ),
    );
  }
}
