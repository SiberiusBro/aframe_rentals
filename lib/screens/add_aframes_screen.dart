import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/background_container.dart';

class AddCabinScreen extends StatefulWidget {
  const AddCabinScreen({super.key});

  @override
  AddCabinScreenState createState() => AddCabinScreenState();
}

class AddCabinScreenState extends State<AddCabinScreen> {
  final _formKey = GlobalKey<FormState>();

  // Basic cabin fields.
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  // New: Description field.
  final TextEditingController _descriptionController = TextEditingController();

  // New: List of images.
  final List<Uint8List> _selectedImageBytesList = [];

  // New: List of extra facilities.
  // Each facility is stored as a map: {'name': <String>, 'price': <double>}
  final List<Map<String, dynamic>> _extraFacilities = [];

  // Controllers for new extra facility input.
  final TextEditingController _facilityNameController = TextEditingController();
  final TextEditingController _facilityPriceController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  /// Fetch the user's current location.
  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _latitudeController.text = position.latitude.toString();
        _longitudeController.text = position.longitude.toString();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  /// Pick one image from the gallery and add it to the list.
  Future<void> _pickImage() async {
    final XFile? image =
    await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      final Uint8List bytes = await image.readAsBytes();
      setState(() {
        _selectedImageBytesList.add(bytes);
      });
    }
  }

  /// Add a new extra facility using the input fields.
  void _addExtraFacility() {
    String facilityName = _facilityNameController.text.trim();
    String facilityPriceText = _facilityPriceController.text.trim();
    if (facilityName.isEmpty || facilityPriceText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter extra options and price')),
      );
      return;
    }
    double? facilityPrice = double.tryParse(facilityPriceText);
    if (facilityPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Facility price must be a number')),
      );
      return;
    }
    setState(() {
      _extraFacilities.add({'name': facilityName, 'price': facilityPrice});
      _facilityNameController.clear();
      _facilityPriceController.clear();
    });
  }

  /// Submit the cabin data.
  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedImageBytesList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one image')),
        );
        return;
      }
      setState(() => _isLoading = true);
      try {
        final User? user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You need to be logged in to add a cabin.')),
          );
          setState(() => _isLoading = false);
          return;
        }

        // Upload each image and gather their URLs.
        List<String> imageUrls = [];
        for (var i = 0; i < _selectedImageBytesList.length; i++) {
          final Uint8List imageBytes = _selectedImageBytesList[i];
          final String fileName =
              'cabins/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
          final Reference ref = FirebaseStorage.instance.ref().child(fileName);
          await ref.putData(imageBytes);
          final String imageUrl = await ref.getDownloadURL();
          imageUrls.add(imageUrl);
        }

        // Save the cabin data, including the description, images, and extra facilities.
        final DatabaseReference dbRef =
        FirebaseDatabase.instance.ref("cabins").push();
        await dbRef.set({
          'id': dbRef.key,
          'title': _titleController.text.trim(),
          'price': double.parse(_priceController.text.trim()),
          'description': _descriptionController.text.trim(),
          'images': imageUrls, // List of image URLs.
          'extras': _extraFacilities, // List of extra facility maps.
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
        setState(() => _isLoading = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titlul cabanei
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Cabin Title'),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Please enter a cabin title'
                      : null,
                ),
                const SizedBox(height: 16),
                // Pret / noapte
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Price per Night'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter a valid price';
                    if (double.tryParse(value) == null) return 'Price must be a number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Please enter a description'
                      : null,
                ),
                const SizedBox(height: 16),
                // Mai multe poze pot fi selectate
                const Text(
                  'Photos',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImageBytesList.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Image.memory(
                          _selectedImageBytesList[index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('Add Photo'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Extra Facilities',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // Lista cu extra facilitati
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _extraFacilities.length,
                  itemBuilder: (context, index) {
                    final facility = _extraFacilities[index];
                    return ListTile(
                      title: Text(facility['name']),
                      subtitle: Text('+ \$${facility['price']}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            _extraFacilities.removeAt(index);
                          });
                        },
                      ),
                    );
                  },
                ),
                // Input fields for new extra facility
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _facilityNameController,
                        decoration: const InputDecoration(labelText: 'Facility Name'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _facilityPriceController,
                        decoration: const InputDecoration(labelText: 'Price'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    IconButton(
                      onPressed: _addExtraFacility,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Latitude Field
                TextFormField(
                  controller: _latitudeController,
                  decoration: const InputDecoration(labelText: 'Latitude'),
                  keyboardType: TextInputType.number,
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Enter latitude'
                      : null,
                ),
                const SizedBox(height: 16),
                // Longitude Field
                TextFormField(
                  controller: _longitudeController,
                  decoration: const InputDecoration(labelText: 'Longitude'),
                  keyboardType: TextInputType.number,
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Enter longitude'
                      : null,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _getCurrentLocation,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Use My Current Location'),
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: SpinKitFadingCube(color: Colors.indigo,size: 50.0,))
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
