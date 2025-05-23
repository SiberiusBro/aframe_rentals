import 'package:aframe_rentals/models/category.dart';
import 'package:aframe_rentals/models/place_model.dart';
import 'package:aframe_rentals/screens/account_details_screen.dart';
import 'package:aframe_rentals/screens/login_screen.dart';
import 'package:aframe_rentals/services/the_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:aframe_rentals/screens/user_profile_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TheProvider(),
        )
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => LoginScreen(),
          '/account-details': (context) => const AccountDetailsScreen(),
          '/edit-profile': (context) => const UserProfileScreen(), // ✅ Add this line
        },
        // keep user login until logout

        // StreamBuilder(
        //   stream: FirebaseAuth.instance.authStateChanges(),
        //   builder: (context, snapshot) {
        //     if (snapshot.hasData) {
        //       return const HomeScreen();
        //     } else {
        //       return const LoginScreen();
        //     }
        //   },
        // ),
      ),
    );
  }
}
