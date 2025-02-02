// lib/main.dart
import 'package:aframe_rentals/screens/add_cabin_screen.dart';
import 'package:aframe_rentals/screens/forgot_pass_screen.dart';
import 'package:aframe_rentals/screens/login_screen.dart';
import 'package:aframe_rentals/screens/manage_cabins_screen.dart';
import 'package:aframe_rentals/screens/profile_screen.dart';
import 'package:aframe_rentals/screens/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'A-Frame Rentals',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      initialRoute: '/auth',
      routes: {
        '/auth': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/signup': (context) => const SignupScreen(),
        '/forgot_password': (context) => const ForgotPassScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/add_cabin': (context) => const AddCabinScreen(),
        '/manage_cabins': (context) => const ManageCabinsScreen(),
      },
    );
  }
}
