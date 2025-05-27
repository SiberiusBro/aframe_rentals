import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationInMap extends StatelessWidget {
  final double latitude;
  final double longitude;

  const LocationInMap({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      myLocationButtonEnabled: false,
      initialCameraPosition: CameraPosition(
        target: LatLng(latitude, longitude),
        zoom: 11,
      ),
      markers: {
        Marker(
          markerId: const MarkerId('place-location'),
          position: LatLng(latitude, longitude),
        ),
      },
    );
  }
}
