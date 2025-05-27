import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'complete_profile_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _emailVerified = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _checkVerification();
  }

  Future<void> _checkVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    await user?.reload(); // 🔄 Refresh the user
    final updatedUser = FirebaseAuth.instance.currentUser;

    setState(() => _emailVerified = updatedUser?.emailVerified ?? false);
  }

  Future<void> _sendVerificationEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Verification email sent!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify Your Email")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.email_outlined, size: 80),
            const SizedBox(height: 20),
            const Text(
              "A verification email has been sent to your email address. Please check and verify.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendVerificationEmail,
              child: const Text("Resend Email"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                setState(() => _loading = true);
                await _checkVerification();
                setState(() => _loading = false);

                if (_emailVerified) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CompleteProfileScreen(),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Email not verified yet.")),
                  );
                }
              },
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text("Continue"),
            )
          ],
        ),
      ),
    );
  }
}