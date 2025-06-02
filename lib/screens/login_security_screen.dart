import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginSecurityScreen extends StatefulWidget {
  const LoginSecurityScreen({super.key});

  @override
  State<LoginSecurityScreen> createState() => _LoginSecurityScreenState();
}

class _LoginSecurityScreenState extends State<LoginSecurityScreen> {
  final user = FirebaseAuth.instance.currentUser;
  bool _isProcessing = false;

  Future<void> _sendPasswordReset() async {
    if (user?.email == null) return;
    setState(() => _isProcessing = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Password Reset"),
            content: const Text("A password reset link was sent to your email. Please log in again after resetting."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  FirebaseAuth.instance.signOut();
                  Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
    setState(() => _isProcessing = false);
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Account?"),
        content: const Text(
          "This will delete your account permanently. This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete Account"),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isProcessing = true);

    try {
      final uid = user!.uid;
      await user!.delete();
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  "For security, please log in again and retry account deletion."),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Delete failed: $e")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Delete failed: $e")),
        );
      }
    }
    setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    final email = user?.email ?? '-';
    final isGoogle = user?.providerData.any((info) => info.providerId == 'google.com') ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text("Login & Security")),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Email card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: const Icon(Icons.email_outlined, size: 28, color: Colors.blue),
                    title: Text(email, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  ),
                ),
                const SizedBox(height: 30),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lock_outline, size: 28, color: Colors.blueGrey),
                        const SizedBox(width: 10),
                        Expanded(
                          child: isGoogle
                              ? const Text(
                            "You signed in with Google.\nNo password is set for this account.",
                            style: TextStyle(fontSize: 16, color: Colors.black54),
                          )
                              : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "••••••••",
                                style: TextStyle(fontSize: 22, letterSpacing: 3),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "Password is not viewable for security reasons.",
                                style: TextStyle(fontSize: 15, color: Colors.black54),
                              ),
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: _sendPasswordReset,
                                    child: const Text("Change"),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isProcessing) const SizedBox(height: 25),
                if (_isProcessing)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
          // Delete account button fixed at the bottom
          Positioned(
            left: 20,
            right: 20,
            bottom: 30,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _deleteAccount,
              icon: const Icon(Icons.delete_forever, color: Colors.white),
              label: const Text(
                "Delete Account",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
