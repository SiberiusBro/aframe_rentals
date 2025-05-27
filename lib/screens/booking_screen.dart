// booking_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/place_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/cloud_notification_service.dart';
import '../services/push_notification_service.dart';

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

    // Fetch user profile
    final requesterSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final requesterName = requesterSnapshot['name'] ?? 'Someone';

    // Add booking record
    await FirebaseFirestore.instance.collection('reservations').add({
      'placeId': widget.place.id,
      'placeTitle': widget.place.title,
      'ownerId': widget.place.vendor,
      'userId': user.uid,
      'userName': requesterName,
      'startDate': _startDate!.toIso8601String(),
      'endDate': _endDate!.toIso8601String(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Send push notification
    final ownerSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.place.vendor)
        .get();

    final ownerToken = ownerSnapshot['deviceToken'];

    await CloudNotificationService.sendNotification(
      token: ownerToken,
      title: 'New Booking Request',
      body: '$requesterName wants to book "${widget.place.title}" from ${DateFormat('yMMMd').format(_startDate!)} to ${DateFormat('yMMMd').format(_endDate!)}',
    );


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
            onPageChanged: (day) => _focusedDay = day,
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
                  const SizedBox(height: 6),
                  Text(
                    "$nights night(s) x \$${widget.place.price} = \$${totalPrice}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ElevatedButton(
            onPressed: (nights > 0) ? _submitBooking : null,
            child: const Text("Request to Book"),
          ),
        ],
      ),
    );
  }
}
