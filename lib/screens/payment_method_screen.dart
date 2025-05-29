import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/place_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentMethodScreen extends StatefulWidget {
  final Place place;
  final DateTime startDate;
  final DateTime endDate;

  const PaymentMethodScreen({
    super.key,
    required this.place,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  String? _selectedMethod; // 'card' or 'cash'
  CardFieldInputDetails? _card;
  bool _isProcessing = false;

  Future<void> _submitPayment() async {
    if (_selectedMethod == 'cash') {
      // Cash payment: create reservation without online payment
      await _createReservation('cash', 'pending');
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Booking requested with Cash.")));
    } else if (_selectedMethod == 'card' && _card != null && _card!.complete) {
      setState(() => _isProcessing = true);
      // Calculate total nights and amount
      int nights = widget.endDate.difference(widget.startDate).inDays;
      if (nights < 1) nights = 1;
      int totalAmount = nights * widget.place.price;
      // 1. Create payment intent on backend
      final response = await http.post(
        Uri.parse('https://us-central1-afframe-rental.cloudfunctions.net/createPaymentIntent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': totalAmount,
          'currency': (widget.place.currency ?? 'RON').toLowerCase(),
          'paymentMethod': 'card',
        }),
      );
      if (response.statusCode != 200) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Payment failed (intent error)")));
        return;
      }
      final responseData = jsonDecode(response.body);
      final clientSecret = responseData['clientSecret'];
      // 2. Confirm payment with Stripe
      try {
        await Stripe.instance.confirmPayment(
          paymentIntentClientSecret: clientSecret,
          data: PaymentMethodParams.card(paymentMethodData: const PaymentMethodData()),
        );
        // If confirmation succeeds, create reservation with payment marked as paid
        await _createReservation('card', 'paid');
        setState(() => _isProcessing = false);
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Payment successful, booking requested.")));
      } catch (e) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Payment failed: $e")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter card details or select cash.")));
    }
  }

  Future<void> _createReservation(String paymentMethod, String paymentStatus) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final requesterSnapshot =
    await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final requesterName = requesterSnapshot.data()?['name'] ?? 'Someone';

    await FirebaseFirestore.instance.collection('reservations').add({
      'placeId': widget.place.id,
      'placeTitle': widget.place.title,
      'ownerId': widget.place.vendor,
      'userId': user.uid,
      'userName': requesterName,
      'startDate': widget.startDate.toIso8601String(),
      'endDate': widget.endDate.toIso8601String(),
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Payment Method")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              title: const Text("Pay with Card"),
              leading: Radio<String>(
                value: 'card',
                groupValue: _selectedMethod,
                onChanged: (v) => setState(() => _selectedMethod = v),
              ),
            ),
            if (_selectedMethod == 'card')
              CardField(
                onCardChanged: (card) => setState(() => _card = card),
              ),
            ListTile(
              title: const Text("Pay with Cash"),
              leading: Radio<String>(
                value: 'cash',
                groupValue: _selectedMethod,
                onChanged: (v) => setState(() => _selectedMethod = v),
              ),
            ),
            const SizedBox(height: 24),
            _isProcessing
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _submitPayment,
              child: const Text("Confirm Payment"),
            ),
          ],
        ),
      ),
    );
  }
}
