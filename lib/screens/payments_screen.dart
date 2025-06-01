import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  CardFieldInputDetails? _card;
  bool _isSaving = false;
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

  Future<void> _saveCard() async {
    if (_card == null || !_card!.complete) return;
    setState(() => _isSaving = true);

    // Simulate storing only safe card metadata (never the number)
    final cardData = {
      'brand': _card!.brand ?? "Unknown",
      'last4': _card!.last4 ?? "----",
      'expMonth': _card!.expiryMonth,
      'expYear': _card!.expiryYear,
      'addedAt': DateTime.now().toIso8601String(),
      'paymentMethodId': "${_card!.brand ?? ""}_${_card!.last4}_${_card!.expiryMonth}_${_card!.expiryYear}_${DateTime.now().millisecondsSinceEpoch}"
    };
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('payment_methods')
        .doc((cardData['paymentMethodId'] ?? '') as String)
        .set(cardData);
    setState(() => _isSaving = false);
    _loadSavedCards();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Card saved (simulated)!")));
  }

  Future<void> _deleteCard(String paymentMethodId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('payment_methods')
        .doc(paymentMethodId)
        .delete();
    _loadSavedCards();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Saved Payment Methods")),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            if (_loadingCards) const LinearProgressIndicator(),
            if (_savedMethods.isNotEmpty) ...[
              const Text("Your Cards:", style: TextStyle(fontWeight: FontWeight.bold)),
              ..._savedMethods.map((m) => ListTile(
                leading: const Icon(Icons.credit_card),
                title: Text("${m['brand']} •••• ${m['last4']}"),
                subtitle: Text("Exp: ${m['expMonth']}/${m['expYear']}"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteCard(m['paymentMethodId']),
                ),
              )),
              const Divider(),
            ],
            const SizedBox(height: 10),
            const Text("Add New Card:"),
            CardField(
              onCardChanged: (card) => setState(() => _card = card),
            ),
            const SizedBox(height: 10),
            _isSaving
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _saveCard,
              child: const Text("Save Card"),
            ),
          ],
        ),
      ),
    );
  }
}
