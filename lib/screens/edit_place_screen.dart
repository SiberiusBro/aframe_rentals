import 'dart:io';
import 'package:aframe_rentals/models/place_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditPlaceScreen extends StatefulWidget {
  final String placeId;
  final Place place;

  const EditPlaceScreen({super.key, required this.placeId, required this.place});

  @override
  State<EditPlaceScreen> createState() => _EditPlaceScreenState();
}

class _EditPlaceScreenState extends State<EditPlaceScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController titleController;
  late TextEditingController addressController;
  late TextEditingController priceController;
  late TextEditingController bedAndBathController;

  List<File> newImages = [];
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.place.title);
    addressController = TextEditingController(text: widget.place.address);
    priceController = TextEditingController(text: widget.place.price.toString());
    bedAndBathController = TextEditingController(text: widget.place.bedAndBathroom);
  }

  Future<void> pickImages() async {
    final List<XFile>? picked = await ImagePicker().pickMultiImage();
    if (picked != null) {
      setState(() {
        newImages = picked.map((x) => File(x.path)).toList();
      });
    }
  }

  Future<List<String>> uploadImages(List<File> files) async {
    final storage = FirebaseStorage.instance;
    List<String> downloadUrls = [];

    for (File file in files) {
      final ref = storage.ref().child('place_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      downloadUrls.add(url);
    }

    return downloadUrls;
  }

  Future<void> updatePlace() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isUploading = true);

    try {
      List<String> imageUrls = widget.place.imageUrls;

      if (newImages.isNotEmpty) {
        imageUrls = await uploadImages(newImages);
      }

      await FirebaseFirestore.instance.collection('places').doc(widget.placeId).update({
        'title': titleController.text,
        'address': addressController.text,
        'price': int.parse(priceController.text),
        'bedAndBathroom': bedAndBathController.text,
        'imageUrls': imageUrls,
        'image': imageUrls.first,
      });

      if (!mounted) return;
      Navigator.pop(context, 'refresh');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update: $e")),
      );
    } finally {
      setState(() => isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Place')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Title"),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(labelText: "Address"),
              ),
              TextFormField(
                controller: priceController,
                decoration: const InputDecoration(labelText: "Price"),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: bedAndBathController,
                decoration: const InputDecoration(labelText: "Bed & Bath"),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: pickImages,
                icon: const Icon(Icons.image),
                label: const Text("Replace Images"),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: (newImages.isNotEmpty ? newImages.map((f) => Image.file(f)) : widget.place.imageUrls.map((url) => Image.network(url)))
                      .map((img) => Padding(padding: const EdgeInsets.all(4), child: SizedBox(height: 100, child: img)))
                      .toList(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isUploading ? null : updatePlace,
                child: isUploading
                    ? const CircularProgressIndicator()
                    : const Text("Update"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
