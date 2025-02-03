import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PickLocationScreen extends StatefulWidget {
  final double initialLat;
  final double initialLng;

  const PickLocationScreen({
    super.key,
    required this.initialLat,
    required this.initialLng,
  });

  @override
  State<PickLocationScreen> createState() => _PickLocationScreenState();
}

class _PickLocationScreenState extends State<PickLocationScreen> {
  late GoogleMapController _mapController;
  LatLng? _pickedLocation;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _pickedLocation = LatLng(widget.initialLat, widget.initialLng);
    // Place an initial marker (optional)
    _markers.add(
      Marker(
        markerId: const MarkerId('pickedLocation'),
        position: _pickedLocation!,
      ),
    );
  }

  /// Called once the GoogleMap is ready.
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  /// Called whenever the user taps on the map.
  void _handleTap(LatLng latLng) {
    setState(() {
      _pickedLocation = latLng;
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('pickedLocation'),
          position: latLng,
        ),
      );
    });
  }

  /// Return the chosen location to the parent screen.
  void _saveLocation() {
    Navigator.pop(context, _pickedLocation);
  }

  @override
  Widget build(BuildContext context) {
    final initialCameraPosition = CameraPosition(
      target: _pickedLocation!,
      zoom: 14,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Pick Location')),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            // Called when user taps the map
            onTap: _handleTap,
            markers: _markers,
            // Start centered on the initial lat/lng
            initialCameraPosition: initialCameraPosition,
            // Optional: enable or disable map UI features:
            // mapType: MapType.normal,
            // myLocationEnabled: true,
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton.icon(
              onPressed: _saveLocation,
              icon: const Icon(Icons.check),
              label: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
