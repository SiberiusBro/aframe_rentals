import 'package:aframe_rentals/screens/add_aframes_screen.dart';
import 'package:aframe_rentals/screens/forgot_pass_screen.dart';
import 'package:aframe_rentals/screens/login_screen.dart';
import 'package:aframe_rentals/screens/manage_aframes_screen.dart';
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
        fontFamily: 'Inter',
        primarySwatch: Colors.indigo,
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(fontSize: 16),
          bodyMedium: TextStyle(fontSize: 14),
        ),
        inputDecorationTheme: InputDecorationTheme(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
