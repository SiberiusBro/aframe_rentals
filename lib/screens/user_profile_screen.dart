import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/user_service.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  // ────────────────────────────────── controllers & state
  final nameController = TextEditingController();
  final ageController  = TextEditingController();
  String gender        = 'Male';

  File?   _selectedImage;
  String? photoUrl;
  bool    isLoading = true;

  // ────────────────────────────────── pick image
  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  // ────────────────────────────────── load profile data
  Future<void> loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final profile = await UserService().getUserProfile();

    setState(() {
      nameController.text = profile?['name']   ?? user.displayName ?? '';
      ageController.text  = profile?['age']?.toString() ?? '';
      gender              = profile?['gender'] ?? 'Male';
      photoUrl            = profile?['photoUrl'] ?? user.photoURL;
      isLoading           = false;
    });
  }

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    super.dispose();
  }

  // ────────────────────────────────── helper for avatar image
  ImageProvider _avatarImage() {
    if (_selectedImage != null) return FileImage(_selectedImage!);
    if (photoUrl != null && photoUrl!.isNotEmpty) return NetworkImage(photoUrl!);
    return const AssetImage('assets/images/default_avatar.png');
  }

  // ────────────────────────────────── UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // avatar
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _avatarImage(),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tap to change profile picture',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // name
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 10),

            // age
            TextField(
              controller: ageController,
              decoration: const InputDecoration(labelText: 'Age'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),

            // gender
            DropdownButtonFormField<String>(
              value: gender,
              decoration: const InputDecoration(labelText: 'Gender'),
              items: const [
                DropdownMenuItem(value: 'Male',   child: Text('Male')),
                DropdownMenuItem(value: 'Female', child: Text('Female')),
                DropdownMenuItem(value: 'Other',  child: Text('Other')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => gender = value);
              },
            ),
            const SizedBox(height: 30),

            // save button
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final age  = int.tryParse(ageController.text.trim()) ?? 0;

                if (name.isEmpty || age <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all fields')),
                  );
                  return;
                }

                try {
                  await UserService().saveUserProfile(
                    name: name,
                    age:  age,
                    gender: gender,
                    imageFile: _selectedImage,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated!')),
                  );
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
