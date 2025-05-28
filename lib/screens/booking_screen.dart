import 'package:aframe_rentals/screens/payment_method_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/place_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/cloud_notification_service.dart';

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
  List<DateTime> _reservedDates = [];  // Dates already booked for this place

  @override
  void initState() {
    super.initState();
    _loadReservedDates();
  }

  // Load all accepted reservations for this place and collect their dates
  Future<void> _loadReservedDates() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('reservations')
        .where('placeId', isEqualTo: widget.place.id)
        .where('status', isEqualTo: 'accepted')
        .get();
    final docs = snapshot.docs;
    List<DateTime> reserved = [];
    for (var doc in docs) {
      final data = doc.data();
      if (data['startDate'] != null && data['endDate'] != null) {
        DateTime start = DateTime.parse(data['startDate']);
        DateTime end = DateTime.parse(data['endDate']);
        // Include all days from start to end inclusive
        DateTime current = start;
        while (!current.isAfter(end)) {
          reserved.add(DateTime(
              current.year, current.month, current.day)); // normalize to date
          current = current.add(const Duration(days: 1));
        }
      }
    }
    setState(() {
      _reservedDates = reserved;
    });
  }

  // Calculate number of nights for the selected range
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
    // Get requester name
    final requesterSnapshot =
    await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final requesterName = requesterSnapshot.data()?['name'] ?? 'Someone';
    // Add reservation entry (pending approval)
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
    // Ensure a chat thread exists for messaging between requester and owner
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
    // Send a push notification to the owner about the new booking request
    final ownerSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.place.vendor)
        .get();
    final ownerToken = ownerSnapshot.data()?['deviceToken'];
    if (ownerToken != null) {
      await CloudNotificationService.sendNotification(
        token: ownerToken,
        title: 'New Booking Request',
        body:
        '${requesterName} wants to book "${widget.place.title}" from ${DateFormat('yMMMd').format(_startDate!)} to ${DateFormat('yMMMd').format(_endDate!)}',
      );
    }
    if (!mounted) return;
    // Close the booking screen after submitting
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Booking request sent")),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate price breakdown for display (assuming Place has pricing info)
    final nights = _calculateNights();
    String unitDisplay = "", totalDisplay = "";
    final currencySymbol = widget.place.currency ?? "€";
    final unitPriceStr = widget.place.price.toString();
    final totalStr = (widget.place.price * (nights > 0 ? nights : 1)).toString();
    if (currencySymbol == 'RON') {
      unitDisplay = "$unitPriceStr RON";
      totalDisplay = "$totalStr RON";
    } else if (RegExp(r'^[A-Za-z]+$').hasMatch(currencySymbol)) {
      unitDisplay = "$unitPriceStr $currencySymbol";
      totalDisplay = "$totalStr $currencySymbol";
    } else {
      unitDisplay = "$currencySymbol$unitPriceStr";
      totalDisplay = "$currencySymbol$totalStr";
    }

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
            // Disable days that are reserved (already booked)
            enabledDayPredicate: (day) {
              // Only allow selection of days not in reserved list
              return !_reservedDates.any((d) => isSameDay(d, day));
            },
            selectedDayPredicate: (day) {
              // Highlight the entire selected range from _startDate to _endDate
              if (_startDate != null && _endDate != null) {
                return day.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
                    day.isBefore(_endDate!.add(const Duration(days: 1)));
              } else if (_startDate != null && _endDate == null) {
                return isSameDay(day, _startDate!);
              }
              return false;
            },
            onDaySelected: (selectedDay, _) {
              setState(() {
                _focusedDay = selectedDay;
                if (_startDate == null || (_startDate != null && _endDate != null)) {
                  // No range selected yet, or a range was already selected – start a new selection
                  _startDate = selectedDay;
                  _endDate = null;
                } else if (selectedDay.isAfter(_startDate!)) {
                  // Attempting to select an end date after the start
                  bool overlapsReserved = _reservedDates.any((d) =>
                  !d.isBefore(_startDate!) && !d.isAfter(selectedDay));
                  if (overlapsReserved) {
                    // The range from _startDate to selectedDay hits an existing reservation
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Selected dates overlap an existing reservation.")),
                    );
                    // Do not set _endDate, keep current _startDate
                    return;
                  }
                  // Valid end date (no overlap)
                  _endDate = selectedDay;
                } else {
                  // Selected a date before the current start date – treat as new start
                  _startDate = selectedDay;
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
              // Color-code availability: green for available, red for reserved
              defaultTextStyle: const TextStyle(color: Colors.green),
              weekendTextStyle: const TextStyle(color: Colors.green),
              disabledTextStyle: const TextStyle(color: Colors.red),
              disabledDecoration: const BoxDecoration(
                color: Color(0x1FFF0000), // semi-transparent red circle
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(color: Colors.white),
              outsideDaysVisible: false,
            ),
          ),
          const SizedBox(height: 16),
          // Display the selected date range and total if a range is picked
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
                    "$nights night(s) x $unitDisplay = $totalDisplay",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PaymentMethodScreen(
                            place: widget.place,
                            startDate: _startDate!,
                            endDate: _endDate!,
                          ),
                        ),
                      );
                    },
                    child: const Text("Proceed to Payment"),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
