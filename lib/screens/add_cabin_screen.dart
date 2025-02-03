import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/background_container.dart';

class AddCabinScreen extends StatefulWidget {
  const AddCabinScreen({super.key});

  @override
  _AddCabinScreenState createState() => _AddCabinScreenState();
}

class _AddCabinScreenState extends State<AddCabinScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  Uint8List? _selectedImageBytes;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  /// 🔹 Fetch the User's Current Location
  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _latitudeController.text = position.latitude.toString();
        _longitudeController.text = position.longitude.toString();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
    }
  }

  /// 🔹 Pick an Image
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      final Uint8List bytes = await image.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
      });
    }
  }

  /// 🔹 Submit the Cabin Data to Firebase
  Future<void> _submit() async {
    if (_formKey.currentState!.validate() && _selectedImageBytes != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final User? user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You need to be logged in to add a cabin.')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        final String fileName = 'cabins/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final Reference ref = FirebaseStorage.instance.ref().child(fileName);
        await ref.putData(_selectedImageBytes!);
        final String imageUrl = await ref.getDownloadURL();

        final DatabaseReference dbRef = FirebaseDatabase.instance.ref("cabins").push();
        await dbRef.set({
          'id': dbRef.key,
          'title': _titleController.text.trim(),
          'price': double.parse(_priceController.text.trim()),
          'imageUrl': imageUrl,
          'userId': user.uid,
          'latitude': double.tryParse(_latitudeController.text) ?? 0.0,
          'longitude': double.tryParse(_longitudeController.text) ?? 0.0,
          'createdAt': DateTime.now().toIso8601String(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cabin successfully added!')),
        );

        await Future.delayed(const Duration(seconds: 1));
        Navigator.pop(context);

      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding cabin: $error')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields, select an image, and set a location')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Cabin')),
      body: BackgroundContainer(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Cabin Title', border: OutlineInputBorder()),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter a cabin title' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Price per Night', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || double.tryParse(value) == null ? 'Enter a valid price' : null,
                ),
                const SizedBox(height: 16),
                _selectedImageBytes == null
                    ? const Text('No image selected')
                    : Image.memory(_selectedImageBytes!, height: 200, width: double.infinity, fit: BoxFit.cover),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Select Image'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _latitudeController,
                  decoration: const InputDecoration(labelText: 'Latitude', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.isEmpty ? 'Enter latitude' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _longitudeController,
                  decoration: const InputDecoration(labelText: 'Longitude', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.isEmpty ? 'Enter longitude' : null,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _getCurrentLocation,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Use My Current Location'),
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Add Cabin'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
