// screens/forgot_pass_screen.dart
import 'package:flutter/material.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_text_field.dart';

class ForgotPassScreen extends StatefulWidget {
  const ForgotPassScreen({super.key});

  @override
  _ForgotPassScreenState createState() => _ForgotPassScreenState();
}

class _ForgotPassScreenState extends State<ForgotPassScreen> {
  final TextEditingController _emailController = TextEditingController();

  // Add your Firebase password reset logic here

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AuthHeader(
                title: "Forgot Password",
              ),
              const SizedBox(height: 32),
              AuthTextField(
                hint: "Email",
                icon: Icons.email_outlined,
                controller: _emailController,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Example: FirebaseAuth.instance.sendPasswordResetEmail(email: _emailController.text.trim());
                },
                child: const Text("Send Reset Link"),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Back to Login",
                    style: TextStyle(color: Colors.indigo),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
