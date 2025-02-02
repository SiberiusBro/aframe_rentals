// widgets/auth_text_field.dart
import 'package:flutter/material.dart';

class AuthTextField extends StatelessWidget {
  final String hint;
  final IconData icon;
  final bool isPassword;
  final TextEditingController? controller; // Added controller parameter

  const AuthTextField({
    super.key,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.controller, // Initialize controller here
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller, // Use the passed-in controller
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: isPassword
            ? IconButton(
          icon: const Icon(Icons.visibility_off),
          onPressed: () {
            // Optionally, you can add logic to toggle password visibility
          },
        )
            : null,
      ),
    );
  }
}
