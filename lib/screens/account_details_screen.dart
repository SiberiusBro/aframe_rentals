// screens/account_details_screen.dart
import 'package:aframe_rentals/models/place_model.dart';
import 'package:aframe_rentals/screens/edit_place_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'edit_profile_screen.dart';

class AccountDetailsScreen extends StatefulWidget {
  const AccountDetailsScreen({super.key});

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  List<Place> _userPlaces = [];
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  String? _userType;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await _fetchUserProfile();
    if (_userType == 'host') {
      await _fetchUserPlaces();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      setState(() {
        _userProfile = doc.data();
        _userType = _userProfile?['userType'] as String? ?? 'guest';
      });
    }
  }

  Future<void> _fetchUserPlaces() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('places')
        .where('userId', isEqualTo: userId)
        .get();
    final List<Place> places = snapshot.docs
        .map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Place.fromJson(data);
    })
        .toList();
    setState(() {
      _userPlaces = places;
      _isLoading = false;
    });
  }

  Future<void> _updateListingStatus(String placeId, bool newStatus) async {
    await FirebaseFirestore.instance.collection('places').doc(placeId).update({
      'isActive': newStatus,
    });
    await _fetchUserPlaces();
  }

  Future<void> _deletePlace(String placeId) async {
    await FirebaseFirestore.instance.collection('places').doc(placeId).delete();
    await _fetchUserPlaces();
  }

  void _editPlace(Place place) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditPlaceScreen(place: place, placeId: place.id!),
      ),
    );
    if (result == 'refresh') {
      await _fetchUserPlaces();
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = timestamp.toDate();
    return DateFormat('dd/MM/yyyy').format(date);
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
    final birthTimestamp = _userProfile?['birthdate'] as Timestamp?;
    final age = _calculateAge(birthTimestamp);

    return Scaffold(
      appBar: AppBar(title: const Text("Account Details")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_userProfile != null) ...[
            ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              leading: CircleAvatar(
                radius: 30,
                backgroundImage: _userProfile!['photoUrl'] != null
                    ? NetworkImage(_userProfile!['photoUrl'])
                    : const AssetImage('assets/images/default_avatar.png')
                as ImageProvider,
              ),
              title: Text(_userProfile!['name'] ?? 'No name'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((_userProfile!['description'] as String?)?.isNotEmpty ==
                      true)
                    Text(
                      _userProfile!['description'],
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  Text(
                    'Age: ${age ?? 'N/A'} • Gender: ${_userProfile!['gender'] ?? 'N/A'}',
                  ),
                  if (birthTimestamp != null)
                    Text(
                      "Birthdate: ${_formatDate(birthTimestamp)}",
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  await Navigator.pushNamed(context, '/edit-profile');
                  _loadAllData(); // refresh after editing
                },
              ),
            ),
            const Divider(height: 32),
          ],

          // If userType == 'host', show their places; otherwise show a guest message
          if (_userType == 'host') ...[
            if (_userPlaces.isEmpty)
              const Center(child: Text("No listings found."))
            else
              ..._userPlaces.map((place) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        place.image,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(place.title),
                    subtitle: Text("Active: ${place.isActive}"),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editPlace(place);
                        } else if (value == 'toggleStatus') {
                          _updateListingStatus(place.id!, !place.isActive);
                        } else if (value == 'delete') {
                          _deletePlace(place.id!);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text("Edit"),
                        ),
                        PopupMenuItem(
                          value: 'toggleStatus',
                          child: Text(place.isActive ? "Delist" : "List"),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text("Delete"),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
          ] else ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  "You are currently a guest.\nOnly hosts can list places.",
                  style: TextStyle(fontSize: 18, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
