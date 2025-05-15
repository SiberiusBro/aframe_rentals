import 'package:aframe_rentals/models/place_model.dart';
import 'package:aframe_rentals/screens/edit_place_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AccountDetailsScreen extends StatefulWidget {
  const AccountDetailsScreen({super.key});

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  List<Place> userPlaces = [];
  Map<String, dynamic>? userProfile;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    await fetchUserProfile();
    await fetchUserPlaces();
  }

  Future<void> fetchUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      setState(() {
        userProfile = doc.data();
      });
    }
  }

  Future<void> fetchUserPlaces() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('places')
        .where('userId', isEqualTo: userId)
        .get();

    final List<Place> places = snapshot.docs
        .map((doc) => Place.fromJson(doc.data()..['id'] = doc.id))
        .toList();

    setState(() {
      userPlaces = places;
      isLoading = false;
    });
  }

  Future<void> updateListingStatus(String placeId, bool newStatus) async {
    await FirebaseFirestore.instance.collection('places').doc(placeId).update({
      'isActive': newStatus,
    });
    await fetchUserPlaces();
  }

  Future<void> deletePlace(String placeId) async {
    await FirebaseFirestore.instance.collection('places').doc(placeId).delete();
    await fetchUserPlaces();
  }

  void editPlace(Place place) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditPlaceScreen(place: place, placeId: place.id!),
      ),
    );

    if (result == 'refresh') {
      await fetchUserPlaces();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Account Details")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (userProfile != null) ...[
            ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              leading: CircleAvatar(
                radius: 30,
                backgroundImage: userProfile!['photoUrl'] != null
                    ? NetworkImage(userProfile!['photoUrl'])
                    : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
              ),
              title: Text(userProfile!['name'] ?? 'No name'),
              subtitle: Text(
                'Age: ${userProfile!['age'] ?? 'N/A'} • Gender: ${userProfile!['gender'] ?? 'N/A'}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  await Navigator.pushNamed(context, '/edit-profile');
                  loadData(); // refresh after editing
                },
              ),
            ),
            const Divider(height: 32),
          ],
          if (userPlaces.isEmpty)
            const Center(child: Text("No listings found."))
          else
            ...userPlaces.map((place) {
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
                        editPlace(place);
                      } else if (value == 'toggleStatus') {
                        updateListingStatus(place.id!, !place.isActive);
                      } else if (value == 'delete') {
                        deletePlace(place.id!);
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
        ],
      ),
    );
  }
}
