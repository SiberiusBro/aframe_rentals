import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng? selected;
  GoogleMapController? mapController;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    await Geolocator.requestPermission();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pick a Location")),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(45.0, 25.0), // Default location
          zoom: 6,
        ),
        onMapCreated: (controller) => mapController = controller,
        onTap: (LatLng point) {
          setState(() {
            selected = point;
          });
        },
        markers: selected == null
            ? {}
            : {
          Marker(
            markerId: const MarkerId('selected'),
            position: selected!,
          ),
        },
      ),
      floatingActionButton: selected == null
          ? null
          : FloatingActionButton.extended(
        onPressed: () {
          Navigator.pop(context, selected);
        },
        label: const Text("Use this location"),
        icon: const Icon(Icons.check),
      ),
    );
  }
}
