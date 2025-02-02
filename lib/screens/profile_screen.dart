import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../widgets/background_container.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  bool _isSaving = false;
  bool _hasCabins = false;

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _nicknameController.text = _currentUser?.displayName ?? '';
    _checkIfUserHasCabins();
  }

  Future<void> _checkIfUserHasCabins() async {
    if (_currentUser == null) return;

    final dbRef = FirebaseDatabase.instance.ref("cabins");
    dbRef.orderByChild("userId").equalTo(_currentUser!.uid).once().then((event) {
      if (event.snapshot.exists) {
        setState(() {
          _hasCabins = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: BackgroundContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${user?.email}', style: const TextStyle(fontSize: 18, color: Colors.white)),
            const SizedBox(height: 20),
            const Text('Nickname:', style: TextStyle(fontSize: 18, color: Colors.white)),
            TextField(controller: _nicknameController, decoration: const InputDecoration(hintText: 'Enter nickname')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/add_cabin');
              },
              child: const Text('Add Cabin'),
            ),
            if (_hasCabins)
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/manage_cabins');
                },
                child: const Text('Manage My Cabins'),
              ),
          ],
        ),
      ),
    );
  }
}
