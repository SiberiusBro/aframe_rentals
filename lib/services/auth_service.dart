import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign in with email/password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result =
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return result.user;
    } catch (e) {
      rethrow;
    }
  }

  // Sign up with email/password
  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      UserCredential result =
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return result.user;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
