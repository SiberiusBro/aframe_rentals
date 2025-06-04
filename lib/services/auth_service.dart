//services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthServices {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();

  // Google sign-in
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();
      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication = await googleSignInAccount.authentication;
        final AuthCredential authCredential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );
        final userCredential = await auth.signInWithCredential(authCredential);
        return userCredential.user;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Email/password sign-in
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      print("Login error: ${e.message}");
      return null;
    }
  }

  Future<User?> signUpWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await result.user?.sendEmailVerification();
      return result.user;
    } on FirebaseAuthException catch (e) {
      print("Sign up error: ${e.message}");
      return null;
    }
  }
}
