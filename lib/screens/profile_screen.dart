import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../widgets/background_container.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
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
    final event = await dbRef
        .orderByChild("userId")
        .equalTo(_currentUser!.uid)
        .once();

    if (event.snapshot.exists) {
      setState(() {
        _hasCabins = true;
      });
    }
  }

  Future<void> _updateNickname() async {
    if (_nicknameController.text.trim().isEmpty) return;
    setState(() => _isSaving = true);

    try {
      await _currentUser?.updateDisplayName(_nicknameController.text.trim());
      await _currentUser?.reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nickname updated!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating nickname: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _signOut() async {
    await AuthService().signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: BackgroundContainer(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Email: ${user?.email}',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
              const SizedBox(height: 20),

              const Text(
                'Nickname:',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              TextField(
                controller: _nicknameController,
                decoration: const InputDecoration(
                  hintText: 'Enter nickname',
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _isSaving ? null : _updateNickname,
                child: _isSaving
                    ? const CircularProgressIndicator()
                    : const Text('Update Nickname'),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/add_cabin');
                },
                child: const Text('Add Cabin'),
              ),
              const SizedBox(height: 8),

              if (_hasCabins)
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/manage_cabins');
                  },
                  child: const Text('Manage My Cabins'),
                ),
              const SizedBox(height: 16),

              // Sign out button
              ElevatedButton(
                onPressed: _signOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
