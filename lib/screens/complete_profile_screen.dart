//screens/complete_profile_screen.dart
import 'dart:io';
import 'package:aframe_rentals/screens/home_screen.dart';
import 'package:aframe_rentals/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _name;
  String? _gender = 'Male';
  DateTime? _birthDate;
  String? _description;
  String? _userType; // "host" or "guest"
  File? _selectedImage;
  bool _isSaving = false;

  Future<void> _pickImage() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initial = DateTime(now.year - 20, now.month, now.day);
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _birthDate == null || _userType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }
    setState(() {
      _isSaving = true;
    });

    try {
      // Call UserService to save:
      await UserService().saveUserProfile(
        name: _name!.trim(),
        gender: _gender!,
        birthdate: _birthDate!,
        description: _description?.trim(),
        userType: _userType!,
        imageFile: _selectedImage,
      );

      // Once saved, navigate to HomeScreen (or wherever is appropriate)
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e')),
      );
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Your Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isSaving
            ? const Center(child: CircularProgressIndicator())
            : Form(
          key: _formKey,
          child: ListView(
            children: [
              // Avatar picker
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Tap to add a profile picture',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
              const SizedBox(height: 20),

              // Name
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => _name = v,
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Gender
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Gender *',
                  border: OutlineInputBorder(),
                ),
                value: _gender,
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
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (v) => _description = v,
              ),
              const SizedBox(height: 16),

              // Account type
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Account Type *',
                  border: OutlineInputBorder(),
                ),
                value: _userType,
                items: const [
                  DropdownMenuItem(value: 'host', child: Text('Host')),
                  DropdownMenuItem(value: 'guest', child: Text('Guest')),
                ],
                onChanged: (v) => setState(() => _userType = v),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _submit,
                child: const Text('Finish'),
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
