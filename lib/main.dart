import 'package:aframe_rentals/models/category.dart';
import 'package:aframe_rentals/models/place_model.dart';
import 'package:aframe_rentals/screens/account_details_screen.dart';
import 'package:aframe_rentals/screens/complete_profile_screen.dart';
import 'package:aframe_rentals/screens/forgot_password_screen.dart';
import 'package:aframe_rentals/screens/home_screen.dart';
import 'package:aframe_rentals/screens/login_screen.dart';
import 'package:aframe_rentals/screens/sign_up_screen.dart';
import 'package:aframe_rentals/screens/user_profile_screen.dart';
import 'package:aframe_rentals/screens/verify_email_screen.dart';
import 'package:aframe_rentals/services/the_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aframe_rentals/widgets/save_device_token.dart';
import 'package:aframe_rentals/screens/notifications_screen.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Background message received: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey = 'pk_test_51RTkpLQmqvmXdvHnIg4uJWrB4OEqSjzQPCwL0MkIe16qp3fVOKbhvjpFQHyGas07iIqpsnwPYtQb6lC0s1Gd8jHE00QINO3JOY';
  await Firebase.initializeApp();

  // 🔐 Save the token if the user is already logged in
  if (FirebaseAuth.instance.currentUser != null) {
    await DeviceTokenService.saveTokenToFirestore();
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _initFirebaseMessaging();
  }

  Future<void> _initFirebaseMessaging() async {
    await FirebaseMessaging.instance.requestPermission();
    final fcmToken = await FirebaseMessaging.instance.getToken();
    debugPrint("FCM Token: $fcmToken");
    // TODO: Save the FCM token to Firestore under the current user document

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        debugPrint('Foreground Notification: ${message.notification!.title}');
        // Optionally show a dialog/snackbar
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TheProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => LoginScreen(),
          '/account-details': (context) => const AccountDetailsScreen(),
          '/edit-profile': (context) {
            final user = FirebaseAuth.instance.currentUser;
            return UserProfileScreen(userId: user?.uid ?? '');
          },
          '/home': (context) => const HomeScreen(),
          '/complete-profile': (context) => const CompleteProfileScreen(),
          '/verify-email': (context) => const VerifyEmailScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/signup': (context) => const SignUpScreen(),
          '/notifications': (context) => const NotificationsScreen(),
        },
      ),
    );
  }
}