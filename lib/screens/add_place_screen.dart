//screens/add_place_screen.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:aframe_rentals/screens/location_picker_screen.dart';
import 'package:geolocator/geolocator.dart';

LatLng? selectedLatLng;

class AddPlaceScreen extends StatefulWidget {
  const AddPlaceScreen({super.key});

  @override
  State<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  final List<Map<String, dynamic>> facilityOptions = [
    {'label': 'Wifi', 'icon': Icons.wifi},
    {'label': 'Room Temperature Control', 'icon': Icons.thermostat},
    // Add more as needed
  ];

  Map<String, bool> selectedFacilities = {
    'Wifi': false,
    'Room Temperature Control': false,
  };
  final List<Map<String, dynamic>> tags = [
    {'name': 'Beach', 'icon': Icons.beach_access},
    {'name': 'Mountain', 'icon': Icons.terrain},
    {'name': 'Rural', 'icon': Icons.grass},
    {'name': 'Urban', 'icon': Icons.location_city},
  ];
  String? selectedTag;

  final _formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();
  final priceController = TextEditingController();
  final descriptionController = TextEditingController();
  final bedsController = TextEditingController();
  final bathroomsController = TextEditingController();

  List<File> selectedImages = [];
  bool isActive = true;
  bool isUploading = false;
  String currency = 'EUR';

  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _setCurrencyByLocation();
  }

  Future<void> _setCurrencyByLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=${position.latitude}&lon=${position.longitude}&format=json',
      );
      final res = await http.get(url);
      final data = json.decode(res.body);
      final countryCode = data['address']['country_code'].toString().toUpperCase();

      setState(() {
        switch (countryCode) {
          case 'RO':
            currency = 'RON';
            break;
          case 'US':
            currency = 'USD';
            break;
          case 'GB':
            currency = 'GBP';
            break;
          default:
            currency = 'EUR';
        }
      });
    } catch (e) {
      // fallback
      currency = 'EUR';
    }
  }

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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in.")),
      );
      return;
    }
    final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final profile = snap.data();
    if (profile == null || profile['name'] == null || profile['birthdate'] == null || profile['gender'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete your profile before listing a place!")),
      );
      return;
    }
    // --- Continue with previous validations and add listing logic ---
    if (!_formKey.currentState!.validate() || selectedImages.isEmpty || selectedLatLng == null || selectedTag == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all fields, pick images and location")),
      );
      return;
    }

    setState(() => isUploading = true);

    try {
      final imageUrls = await uploadImages(selectedImages);
      final docId = const Uuid().v4();
      final userId = FirebaseAuth.instance.currentUser?.uid;

      await FirebaseFirestore.instance.collection('places').doc(docId).set({
        'id': docId,
        'title': titleController.text,
        'price': int.parse(priceController.text),
        'currency': currency,
        'latitude': selectedLatLng!.latitude,
        'longitude': selectedLatLng!.longitude,
        'rating': 4.5,
        'review': 0,
        'date': DateTime.now().toIso8601String(),
        'yearOfHostin': 1,
        'isActive': isActive,
        'imageUrls': imageUrls,
        'image': imageUrls.first,
        'vendorProfession': 'Host',
        'vendorProfile': '',
        'ownerId': userId, // <<< THIS IS NOW CORRECT
        'description': descriptionController.text,
        'beds': int.tryParse(bedsController.text) ?? 1,
        'bathrooms': int.tryParse(bathroomsController.text) ?? 1,
        'placeTag': selectedTag,
        'facilities': selectedFacilities,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Place added successfully")),
      );
      Navigator.pop(context, 'refresh');
    } catch (e) {
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
    priceController.dispose();
    descriptionController.dispose();
    bedsController.dispose();
    bathroomsController.dispose();
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
              _styledField(titleController, 'Title'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price / Night',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: currency,
                    items: ['EUR', 'USD', 'RON', 'GBP']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) => setState(() => currency = val!),
                  )
                ],
              ),
              const SizedBox(height: 12),
              _styledField(descriptionController, 'Description', maxLines: 3),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _styledField(bedsController, 'Beds', isNum: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _styledField(bathroomsController, 'Bathrooms', isNum: true)),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  final LatLng? picked = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LocationPickerScreen()),
                  );
                  if (picked != null) {
                    setState(() => selectedLatLng = picked);
                  }
                },
                icon: const Icon(Icons.map),
                label: Text(
                  selectedLatLng != null
                      ? "Location: ${selectedLatLng!.latitude.toStringAsFixed(4)}, ${selectedLatLng!.longitude.toStringAsFixed(4)}"
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
              const SizedBox(height: 16),
              Text('Select a Tag', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: tags.map((tag) {
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(tag['icon'], size: 18),
                        SizedBox(width: 6),
                        Text(tag['name']),
                      ],
                    ),
                    selected: selectedTag == tag['name'],
                    onSelected: (_) {
                      setState(() => selectedTag = tag['name']);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              ExpansionTile(
                title: const Text(
                  'Extra Features+',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                children: facilityOptions.map((facility) {
                  final label = facility['label'] as String;
                  final icon = facility['icon'] as IconData;
                  return SwitchListTile(
                    title: Row(
                      children: [
                        Icon(icon, size: 20),
                        const SizedBox(width: 8),
                        Text(label),
                      ],
                    ),
                    value: selectedFacilities[label] ?? false,
                    onChanged: (val) {
                      setState(() {
                        selectedFacilities[label] = val;
                      });
                    },
                  );
                }).toList(),
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

  Widget _styledField(TextEditingController controller, String label,
      {int maxLines = 1, bool isNum = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      maxLines: maxLines,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
    );
  }
}
