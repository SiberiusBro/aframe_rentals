import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_text_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signUp() async {
    setState(() => _isLoading = true);

    try {
      final fullName = _fullNameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
        throw FirebaseAuthException(
            code: 'invalid-input', message: 'All fields are required.');
      }
      if (password.length < 6) {
        throw FirebaseAuthException(
            code: 'weak-password', message: 'Password must be at least 6 characters.');
      }

      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Set the display name for the user
      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(fullName);
        await userCredential.user!.reload();
      }

      // Navigate to home
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-up failed: ${e.message}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AuthHeader(title: "Create Account"),
              const SizedBox(height: 32),

              AuthTextField(
                hint: "Full Name",
                icon: Icons.person_outline,
                controller: _fullNameController,
              ),
              const SizedBox(height: 16),

              AuthTextField(
                hint: "Email",
                icon: Icons.email_outlined,
                controller: _emailController,
              ),
              const SizedBox(height: 16),

              AuthTextField(
                hint: "Password",
                icon: Icons.lock_outline,
                isPassword: true,
                controller: _passwordController,
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _signUp,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Sign Up"),
              ),
              const SizedBox(height: 16),

              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Already have an account? Login",
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
