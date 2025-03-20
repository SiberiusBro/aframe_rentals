import 'package:aframe_rentals/models/category.dart';
import 'package:aframe_rentals/models/place_model.dart';
import 'package:aframe_rentals/screens/add_aframes_screen.dart';
import 'package:aframe_rentals/screens/forgot_pass_screen.dart';
import 'package:aframe_rentals/screens/login_screen.dart';
import 'package:aframe_rentals/screens/manage_aframes_screen.dart';
import 'package:aframe_rentals/screens/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // This ensures Firebase creates an app with the name "dev project"
  await Firebase.initializeApp(
    name: "dev project",
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}
