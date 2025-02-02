import 'package:flutter/material.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_text_field.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

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
              const AuthHeader(title: "Create Account"),
              const SizedBox(height: 32),
              const AuthTextField(
                hint: "Full Name",
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              const AuthTextField(
                hint: "Email",
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 16),
              const AuthTextField(
                hint: "Password",
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {},
                child: const Text("Sign Up"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}