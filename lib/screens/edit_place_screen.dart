//screens/edit_place_screen.dart
import 'dart:io';
import 'package:aframe_rentals/models/place_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:table_calendar/table_calendar.dart';

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
  late TextEditingController priceController;
  late TextEditingController descriptionController;
  late TextEditingController bedsController;
  late TextEditingController bathroomsController;

  List<File> newImages = [];
  bool isUploading = false;

  final List<Map<String, dynamic>> facilityOptions = [
    {'label': 'Wifi', 'icon': Icons.wifi},
    {'label': 'Room Temperature Control', 'icon': Icons.thermostat},
    // Add more as needed
  ];
  late Map<String, bool> selectedFacilities;

  Set<DateTime> _blockedDates = {};
  Set<DateTime> _bookedDates = {};
  bool _loadingBlocked = true;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.place.title);
    priceController = TextEditingController(text: widget.place.price.toString());
    descriptionController = TextEditingController(text: widget.place.description ?? '');
    bedsController = TextEditingController(text: widget.place.beds?.toString() ?? '');
    bathroomsController = TextEditingController(text: widget.place.bathrooms?.toString() ?? '');
    selectedFacilities = {
      for (var facility in facilityOptions)
        facility['label'] as String:
        widget.place.facilities != null && widget.place.facilities![facility['label']] == true
            ? true
            : false
    };
    _loadBlockedAndBookedDates();
  }

  Future<void> _loadBlockedAndBookedDates() async {
    // Load blocked (host custom) dates
    final doc = await FirebaseFirestore.instance.collection('places').doc(widget.placeId).get();
    Set<DateTime> blocks = {};
    if (doc.exists && doc.data()!['blockedDates'] != null) {
      for (var dateStr in (doc.data()!['blockedDates'] as List)) {
        final parts = dateStr.split('-').map(int.parse).toList();
        blocks.add(DateTime(parts[0], parts[1], parts[2]));
      }
    }

    // Load booked dates (from reservations where status == accepted)
    final resSnap = await FirebaseFirestore.instance
        .collection('reservations')
        .where('placeId', isEqualTo: widget.placeId)
        .where('status', isEqualTo: 'accepted')
        .get();

    Set<DateTime> booked = {};
    for (var doc in resSnap.docs) {
      final data = doc.data();
      DateTime start = DateTime.parse(data['startDate']);
      DateTime end = DateTime.parse(data['endDate']);
      for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
        booked.add(DateTime(d.year, d.month, d.day));
      }
    }

    setState(() {
      _blockedDates = blocks;
      _bookedDates = booked;
      _loadingBlocked = false;
    });
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
        'price': int.parse(priceController.text),
        'description': descriptionController.text,
        'beds': int.tryParse(bedsController.text) ?? 1,
        'bathrooms': int.tryParse(bathroomsController.text) ?? 1,
        'imageUrls': imageUrls,
        'image': imageUrls.first,
        'facilities': selectedFacilities,
        'blockedDates': _blockedDates
            .map((d) =>
        "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}")
            .toList(),
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
      appBar: AppBar(title: const Text('Edit Place')),
      body: _loadingBlocked
          ? const Center(child: CircularProgressIndicator())
          : Padding(
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
                controller: priceController,
                decoration: const InputDecoration(labelText: "Price / Night"),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
                maxLines: 3,
              ),
              TextFormField(
                controller: bedsController,
                decoration: const InputDecoration(labelText: "Beds"),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: bathroomsController,
                decoration: const InputDecoration(labelText: "Bathrooms"),
                keyboardType: TextInputType.number,
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
              const SizedBox(height: 24),

              // Calendar for host to block/unblock dates & see booked dates
              const Text(
                'Block/Unblock Dates (Unavailable for booking):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: DateTime.now(),
                calendarFormat: CalendarFormat.month,
                selectedDayPredicate: (day) {
                  final d = DateTime(day.year, day.month, day.day);
                  return _blockedDates.contains(d);
                },
                enabledDayPredicate: (day) {
                  final d = DateTime(day.year, day.month, day.day);
                  // Host can toggle only if not booked
                  return !_bookedDates.contains(d);
                },
                onDaySelected: (selectedDay, _) {
                  final d = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
                  // Ignore clicks on booked dates!
                  if (_bookedDates.contains(d)) return;
                  setState(() {
                    if (_blockedDates.contains(d)) {
                      _blockedDates.remove(d);
                    } else {
                      _blockedDates.add(d);
                    }
                  });
                },
                calendarStyle: CalendarStyle(
                  selectedDecoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: const TextStyle(color: Colors.white),
                  todayDecoration: BoxDecoration(
                    color: Colors.green.shade100,
                    shape: BoxShape.circle,
                  ),
                  weekendTextStyle: const TextStyle(color: Colors.black),
                  outsideDaysVisible: false,
                  // Booked dates: visually red and not selectable
                  disabledDecoration: BoxDecoration(
                    color: Colors.red.shade300,
                    shape: BoxShape.circle,
                  ),
                  disabledTextStyle: const TextStyle(color: Colors.white),
                ),
              ),

              const SizedBox(height: 24),
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
