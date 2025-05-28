import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:aframe_rentals/models/place_model.dart';

class PaymentMethodScreen extends StatefulWidget {
  final Place place;
  final DateTime startDate;
  final DateTime endDate;

  PaymentMethodScreen({
    Key? key,
    required this.place,
    required this.startDate,
    required this.endDate,
  }) : super(key: key);

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  String? _selectedMethod = 'card';
  CardFieldInputDetails? _card;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final nights = widget.endDate.difference(widget.startDate).inDays;
    final totalPrice = widget.place.price * (nights > 0 ? nights : 1);

    return Scaffold(
      appBar: AppBar(title: Text('Select Payment Method')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            ListTile(
              leading: Radio<String>(
                value: 'card',
                groupValue: _selectedMethod,
                onChanged: (v) => setState(() => _selectedMethod = v),
              ),
              title: Text('Pay with Card'),
              onTap: () => setState(() => _selectedMethod = 'card'),
            ),
            if (_selectedMethod == 'card')
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: CardField(
                  onCardChanged: (card) => setState(() => _card = card),
                ),
              ),
            Divider(),
            ListTile(
              leading: Radio<String>(
                value: 'cash',
                groupValue: _selectedMethod,
                onChanged: (v) => setState(() => _selectedMethod = v),
              ),
              title: Text('Pay with Cash'),
              onTap: () => setState(() => _selectedMethod = 'cash'),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: _isProcessing
                  ? null
                  : () => _submitPayment(totalPrice.toDouble()), // ensure double
              child: _isProcessing
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : Text('Confirm Payment'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitPayment(double totalPrice) async {
    if (_selectedMethod == 'cash') {
      await _createReservation('cash', 'pending');
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking requested with Cash.')),
      );
      return;
    }

    if (_selectedMethod == 'card' && (_card == null || !_card!.complete)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in card details.')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // 1. Call backend to create payment intent
      final amount = (totalPrice * 100).toInt(); // e.g. RON to bani, or USD to cents
      final response = await http.post(
        Uri.parse('https://us-central1-afframe-rental.cloudfunctions.net/createPaymentIntent'), // CHANGE THIS
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': amount,
          'currency': widget.place.currency.toLowerCase(),
        }),
      );
      final json = jsonDecode(response.body);
      final clientSecret = json['clientSecret'];
      if (clientSecret == null) throw Exception('No clientSecret returned');

      // 2. Confirm the payment (NEW NAMED PARAMETERS)
      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );

      // 3. Success, mark reservation as paid
      await _createReservation('card', 'paid');
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment successful, booking requested.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: ${e.toString()}')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _createReservation(String method, String status) async {
    final user = FirebaseAuth.instance.currentUser!;
    await FirebaseFirestore.instance.collection('reservations').add({
      'placeId': widget.place.id,
      'userId': user.uid,
      'startDate': widget.startDate,
      'endDate': widget.endDate,
      'paymentMethod': method,
      'paymentStatus': status,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
