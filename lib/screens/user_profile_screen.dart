//screens/user_profile_screen.dart
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
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      if (doc.exists) {
        _userProfile = doc.data();
      }
    } catch (e) {
      _userProfile = null;
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  int? _calculateAge(Timestamp? birthTimestamp) {
    if (birthTimestamp == null) return null;
    final birthDate = birthTimestamp.toDate();
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
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
              backgroundImage: (profile['photoUrl'] != null &&
                  (profile['photoUrl'] as String).isNotEmpty)
                  ? NetworkImage(profile['photoUrl'])
                  : const AssetImage('assets/images/default_avatar.png')
              as ImageProvider,
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
          const SizedBox(height: 8),
          Center(
            child: Text(
              [
                if (profile['birthdate'] != null)
                  "Age: ${_calculateAge(profile['birthdate'])}",
                if (profile['gender'] != null && profile['gender'] != '')
                  "Gender: ${profile['gender']}"
              ].where((e) => e.isNotEmpty).join(' • '),
              style: const TextStyle(fontSize: 16, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ),
          if ((profile['description'] ?? '').toString().trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Center(
              child: Text(
                profile['description'],
                style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Divider(),

          // REVIEWS SECTION
          FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('reviews')
                .where('targetUserId', isEqualTo: widget.userId)
                .orderBy('timestamp', descending: true)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No reviews yet.'));
              }
              final reviews = snapshot.data!.docs;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reviews as Host:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  ...reviews.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(data['guestName'] ?? 'Someone'),
                      subtitle: Text(data['comment'] ?? ''),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          5,
                              (i) => Icon(
                            i < ((data['rating'] ?? 0) as double).round()
                                ? Icons.star
                                : Icons.star_border,
                            size: 20,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              );
            },
          ),
        ],
      )),
    );
  }
}
