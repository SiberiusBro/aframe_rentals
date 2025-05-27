import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/place_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/cloud_notification_service.dart';
// import '../services/push_notification_service.dart'; // only if still needed

class BookingScreen extends StatefulWidget {
  final Place place;
  const BookingScreen({super.key, required this.place});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime _focusedDay = DateTime.now();

  int _calculateNights() {
    if (_startDate != null && _endDate != null) {
      return _endDate!.difference(_startDate!).inDays;
    }
    return 0;
  }

  Future<void> _submitBooking() async {
    if (_startDate == null || _endDate == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Fetch user profile for name
    final requesterSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final requesterName = requesterSnapshot.data()?['name'] ?? 'Someone';

    // Add booking record
    await FirebaseFirestore.instance.collection('reservations').add({
      'placeId': widget.place.id,
      'placeTitle': widget.place.title,
      'ownerId': widget.place.vendor,
      'userId': user.uid,
      'userName': requesterName,
      'startDate': _startDate!.toIso8601String(),
      'endDate': _endDate!.toIso8601String(),
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Ensure a chat thread exists for this booking
    final participants = [user.uid, widget.place.vendor]..sort();
    final chatDocId = "${participants[0]}_${participants[1]}_${widget.place.id}";
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatDocId);
    final chatDoc = await chatRef.get();
    if (!chatDoc.exists) {
      await chatRef.set({
        'participants': [user.uid, widget.place.vendor],
        'placeId': widget.place.id,
        'placeTitle': widget.place.title,
        'lastMessage': '',
        'lastMessageTime': DateTime.now().toIso8601String(),
        'lastMessageSender': '',
        'unreadCount_${user.uid}': 0,
        'unreadCount_${widget.place.vendor}': 0,
      });
    } else {
      await chatRef.set({
        'participants': [user.uid, widget.place.vendor],
        'placeId': widget.place.id,
        'placeTitle': widget.place.title,
        'unreadCount_${user.uid}': 0,
        'unreadCount_${widget.place.vendor}': 0,
      }, SetOptions(merge: true));
    }

    // Send push notification to place owner
    final ownerSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.place.vendor)
        .get();
    final ownerToken = ownerSnapshot.data()?['deviceToken'];
    if (ownerToken != null) {
      await CloudNotificationService.sendNotification(
        token: ownerToken,
        title: 'New Booking Request',
        body: '$requesterName wants to book "${widget.place.title}" from ${DateFormat('yMMMd').format(_startDate!)} to ${DateFormat('yMMMd').format(_endDate!)}',
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Booking request sent!")),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final nights = _calculateNights();
    final totalPrice = nights * widget.place.price;

    return Scaffold(
      appBar: AppBar(title: const Text('Select Dates')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            onPageChanged: (day) => setState(() => _focusedDay = day),
            calendarFormat: CalendarFormat.month,
            selectedDayPredicate: (day) {
              if (_startDate != null && _endDate != null) {
                return day.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
                    day.isBefore(_endDate!.add(const Duration(days: 1)));
              } else if (_startDate != null && _endDate == null) {
                return isSameDay(day, _startDate!);
              }
              return false;
            },
            onDaySelected: (selected, _) {
              setState(() {
                _focusedDay = selected;
                if (_startDate == null || (_startDate != null && _endDate != null)) {
                  _startDate = selected;
                  _endDate = null;
                } else if (selected.isAfter(_startDate!)) {
                  _endDate = selected;
                } else {
                  _startDate = selected;
                  _endDate = null;
                }
              });
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              weekendTextStyle: const TextStyle(color: Colors.black),
              outsideDaysVisible: false,
            ),
          ),
          const SizedBox(height: 16),
          if (_startDate != null && _endDate != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    "Selected: ${DateFormat('yMMMd').format(_startDate!)} - ${DateFormat('yMMMd').format(_endDate!)}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    "$nights night(s) x \$${widget.place.price} = \$${totalPrice}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _submitBooking,
                    child: const Text("Request Booking"),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
