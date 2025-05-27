import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      if (doc.exists) {
        _userProfile = doc.data();
      }
    } catch (e) {
      // Handle error (e.g., no permission or network issue)
      _userProfile = null;
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _userProfile;
    return Scaffold(
      appBar: AppBar(title: const Text("User Profile")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (profile == null
          ? const Center(child: Text("User not found."))
          : ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const SizedBox(height: 30),
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.black26,
              backgroundImage: (profile['photoUrl'] != null && (profile['photoUrl'] as String).isNotEmpty)
                  ? NetworkImage(profile['photoUrl'])
                  : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              profile['name'] ?? 'No name provided',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          if (profile['age'] != null || profile['gender'] != null) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                "Age: ${profile['age'] ?? 'N/A'} • Gender: ${profile['gender'] ?? 'N/A'}",
                style: const TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          // Additional public info or reviews could be added here in the future.
          if (profile['age'] == null && profile['gender'] == null) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                "No additional information provided.",
                style: const TextStyle(fontSize: 14, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      )),
    );
  }
}
