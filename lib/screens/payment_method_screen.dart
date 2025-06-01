import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/place_model.dart';
import 'home_screen.dart';
import 'payments_screen.dart';

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
  String? _selectedCardId;
  CardFieldInputDetails? _card;
  bool _isProcessing = false;
  List<Map<String, dynamic>> _savedMethods = [];
  bool _loadingCards = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCards();
  }

  Future<void> _loadSavedCards() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('payment_methods')
        .get();
    setState(() {
      _savedMethods = snap.docs.map((d) => d.data()).toList();
      _loadingCards = false;
    });
  }

  Future<void> _addNewCard() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentsScreen()));
    _loadSavedCards();
  }

  Future<void> _submitPayment() async {
    if (_selectedMethod == 'cash') {
      await _createReservation('cash', 'pending');
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Booking requested with Cash.")),
        );
      }
    } else if (_selectedMethod == 'card') {
      if ((_selectedCardId == null && (_card == null || !_card!.complete))) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please select or add a card.")));
        return;
      }
      setState(() => _isProcessing = true);

      // Calculate total nights and amount
      int nights = widget.endDate.difference(widget.startDate).inDays;
      if (nights < 1) nights = 1;
      int totalAmount = nights * widget.place.price;

      // Here: call your backend for payment intent, then confirm via Stripe.
      // For this demo, we will just simulate as "paid"
      await Future.delayed(const Duration(seconds: 1)); // simulate payment

      await _createReservation('card', 'paid');
      setState(() => _isProcessing = false);
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment successful, booking requested.")),
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
              _loadingCards
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                children: [
                  ..._savedMethods.map((m) => RadioListTile<String>(
                    value: m['paymentMethodId'],
                    groupValue: _selectedCardId,
                    onChanged: (val) => setState(() => _selectedCardId = val),
                    title: Text("${m['brand']} •••• ${m['last4']}"),
                    subtitle: Text("Exp: ${m['expMonth']}/${m['expYear']}"),
                  )),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text("Add New Card"),
                    onPressed: _addNewCard,
                  ),
                  if (_selectedCardId == null) ...[
                    const SizedBox(height: 10),
                    const Text("Or pay with a one-time card:"),
                    CardField(
                      onCardChanged: (card) => setState(() => _card = card),
                    ),
                  ]
                ],
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
