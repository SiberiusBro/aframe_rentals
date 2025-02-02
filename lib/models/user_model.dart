// lib/models/user_model.dart
class UserModel {
  final String uid;
  final String email;
  final String? displayName;

  UserModel({required this.uid, required this.email, this.displayName});

  // You can add a factory method to create a UserModel from a Firebase user
  factory UserModel.fromFirebaseUser(dynamic user) {
    return UserModel(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
    );
  }
}
