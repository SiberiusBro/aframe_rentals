import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'location_picker_screen.dart';

LatLng? selectedLatLng;

class AddPlaceScreen extends StatefulWidget {
  const AddPlaceScreen({super.key});

  @override
  State<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  final _formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();
  final addressController = TextEditingController();
  final priceController = TextEditingController();
  final vendorController = TextEditingController();
  final bedAndBathController = TextEditingController();

  List<File> selectedImages = [];
  bool isActive = true;
  bool isUploading = false;

  final picker = ImagePicker();

  Future<void> pickImages() async {
    final List<XFile>? picked = await picker.pickMultiImage();
    if (picked != null) {
      setState(() {
        selectedImages = picked.map((xfile) => File(xfile.path)).toList();
      });
    }
  }

  Future<List<String>> uploadImages(List<File> files) async {
    final storage = FirebaseStorage.instance;
    List<String> downloadUrls = [];

    for (File file in files) {
      final id = const Uuid().v4();
      final ref = storage.ref().child('place_images/$id.jpg');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      downloadUrls.add(url);
    }

    return downloadUrls;
  }

  Future<void> submitPlace() async {
    if (!_formKey.currentState!.validate() || selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all fields and pick images")),
      );
      return;
    }

    setState(() => isUploading = true);

    try {
      final imageUrls = await uploadImages(selectedImages);

      final docId = const Uuid().v4();
      final userId = FirebaseAuth.instance.currentUser?.uid;

      await FirebaseFirestore.instance.collection('places').doc(docId).set({
        'title': titleController.text,
        'address': addressController.text,
        'price': int.parse(priceController.text),
        'vendor': vendorController.text,
        'bedAndBathroom': bedAndBathController.text,
        'latitude': selectedLatLng?.latitude ?? 0,
        'longitude': selectedLatLng?.longitude ?? 0,
        'rating': 4.5,
        'review': 0,
        'date': DateTime.now().toIso8601String(),
        'yearOfHostin': 1,
        'isActive': isActive,
        'imageUrls': imageUrls,
        'image': imageUrls.first,
        'vendorProfession': 'Host',
        'vendorProfile': '', // optional
        'userId': userId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Place added successfully")),
      );
      Navigator.pop(context, 'refresh');
    } catch (e) {
      print("Upload error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to add place")),
      );
    } finally {
      setState(() => isUploading = false);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    addressController.dispose();
    priceController.dispose();
    vendorController.dispose();
    bedAndBathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add New Place")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              TextFormField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: vendorController,
                decoration: const InputDecoration(labelText: 'Vendor'),
              ),
              TextFormField(
                controller: bedAndBathController,
                decoration: const InputDecoration(labelText: 'Bed & Bath Info'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final LatLng? picked = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
                  );
                  if (picked != null) {
                    setState(() {
                      selectedLatLng = picked;
                    });
                  }
                },
                icon: const Icon(Icons.map),
                label: Text(
                  selectedLatLng != null
                      ? "Selected: ${selectedLatLng!.latitude.toStringAsFixed(4)}, ${selectedLatLng!.longitude.toStringAsFixed(4)}"
                      : "Pick Location",
                ),
              ),

              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: pickImages,
                icon: const Icon(Icons.image),
                label: const Text("Pick Images"),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: selectedImages
                      .map((file) => Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Image.file(file, height: 100),
                  ))
                      .toList(),
                ),
              ),
              SwitchListTile(
                title: const Text("Active Listing"),
                value: isActive,
                onChanged: (value) => setState(() => isActive = value),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isUploading ? null : submitPlace,
                child: isUploading
                    ? const CircularProgressIndicator()
                    : const Text("Submit Place"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
