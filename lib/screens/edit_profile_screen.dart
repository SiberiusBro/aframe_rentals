import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  String? _gender;
  DateTime? _birthDate;
  String? _photoUrl;
  File? _newImageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!doc.exists) return;
    final data = doc.data()!;
    setState(() {
      _nameController.text = data['name'] ?? '';
      _descController.text = data['description'] ?? '';
      _gender = data['gender'] as String?;
      _photoUrl = data['photoUrl'] as String?;
      if (data['birthdate'] != null) {
        _birthDate = (data['birthdate'] as Timestamp).toDate();
      }
    });
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked != null) {
      setState(() {
        _newImageFile = File(picked.path);
      });
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initial = _birthDate ?? DateTime(now.year - 20, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  Future<String?> _uploadAvatar(File imageFile, String uid) async {
    final ref = FirebaseStorage.instance.ref().child('user_avatars/$uid.jpg');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;
    String? imageUrl = _photoUrl;

    // Upload new avatar if selected
    if (_newImageFile != null) {
      imageUrl = await _uploadAvatar(_newImageFile!, uid);
      await user.updatePhotoURL(imageUrl);
    }

    // Update display name in FirebaseAuth
    final newName = _nameController.text.trim();
    await user.updateDisplayName(newName);

    // Write to Firestore
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'name': newName,
      'gender': _gender,
      'birthdate': Timestamp.fromDate(_birthDate!),
      'description': _descController.text.trim(),
      'photoUrl': imageUrl,
    }, SetOptions(merge: true));

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
    Navigator.pop(context, 'refresh');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar picker / preview
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _newImageFile != null
                        ? FileImage(_newImageFile!)
                        : (_photoUrl != null && _photoUrl!.isNotEmpty
                        ? NetworkImage(_photoUrl!)
                        : const AssetImage('assets/images/default_avatar.png')
                    ) as ImageProvider,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Tap avatar to change', style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 20),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Gender
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(
                  labelText: 'Gender *',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _gender = v),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Birthdate
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickBirthDate,
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Birthdate (DD/MM/YYYY) *',
                            border: OutlineInputBorder(),
                          ),
                          controller: TextEditingController(
                            text: _birthDate == null
                                ? ''
                                : '${_birthDate!.day.toString().padLeft(2, '0')}/'
                                '${_birthDate!.month.toString().padLeft(2, '0')}/'
                                '${_birthDate!.year}',
                          ),
                          validator: (_) =>
                          _birthDate == null ? 'Required' : null,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _pickBirthDate,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description (optional)
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _saveProfile,
                child: const Text('Save Changes'),
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
