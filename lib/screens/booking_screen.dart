// At the top with other imports
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/place_model.dart';
import 'payment_method_screen.dart';

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

  // --- ADDED: Require user to be logged in AND have a profile before booking ---
  Future<bool> _canBook() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to book.')),
      );
      return false;
    }
    final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final profile = snap.data();
    if (profile == null || profile['name'] == null || profile['age'] == null || profile['gender'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete your profile before booking!')),
      );
      return false;
    }
    return true;
  }

  void _openPaymentMethodScreen() async {
    if (_startDate == null || _endDate == null) return;
    if (!await _canBook()) return; // <--- Block if not allowed
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
  }

  @override
  Widget build(BuildContext context) {
    final nights = _calculateNights();
    final totalPrice = nights * widget.place.price;
    Locale locale = Localizations.localeOf(context);
    String countryCode = locale.countryCode ?? 'US';
    String currencySymbol;
    if (countryCode == 'RO') {
      currencySymbol = '';
    } else if (countryCode == 'GB') {
      currencySymbol = '£';
    } else if (countryCode == 'US' || countryCode == 'AU' || countryCode == 'CA' || countryCode == 'NZ') {
      currencySymbol = '\$';
    } else if (['AT','BE','CY','EE','FI','FR','DE','GR','IE','IT','LV','LT','LU','MT','NL','PT','SK','SI','ES']
        .contains(countryCode)) {
      currencySymbol = '€';
    } else {
      currencySymbol = NumberFormat.simpleCurrency(locale: locale.toString()).currencySymbol;
    }
    String unitPriceStr = widget.place.price.toString();
    if (unitPriceStr.endsWith('.0')) unitPriceStr = unitPriceStr.substring(0, unitPriceStr.length - 2);
    String totalStr = totalPrice.toString();
    if (totalStr.endsWith('.0')) totalStr = totalStr.substring(0, totalStr.length - 2);
    late String unitDisplay;
    late String totalDisplay;
    if (countryCode == 'RO') {
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
            selectedDayPredicate: (day) {
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
                  _startDate = selectedDay;
                  _endDate = null;
                } else if (selectedDay.isAfter(_startDate!)) {
                  _endDate = selectedDay;
                } else {
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
              weekendTextStyle: const TextStyle(color: Colors.black),
              outsideDaysVisible: false,
            ),
          ),
          const SizedBox(height: 16),
          if (_startDate != null && _endDate != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
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
                    onPressed: _openPaymentMethodScreen,
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
