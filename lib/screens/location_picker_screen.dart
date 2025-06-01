//screens/location_picker_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:uuid/uuid.dart';

class LocationPickerScreen extends StatefulWidget {
  @override
  _LocationPickerScreenState createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  GoogleMapController? _mapController;
  LatLng _selectedLocation = const LatLng(45.7489, 21.2087);
  final String _sessionToken = const Uuid().v4();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Location')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation,
              zoom: 14.0,
            ),
            onMapCreated: (controller) => _mapController = controller,
            markers: {
              Marker(
                markerId: const MarkerId('selected-location'),
                position: _selectedLocation,
              ),
            },
            onTap: (LatLng position) {
              setState(() {
                _selectedLocation = position;
              });
              _mapController?.animateCamera(CameraUpdate.newLatLng(position));
            },
          ),
          Positioned(
            top: 10,
            left: 15,
            right: 15,
            child: Material(
              elevation: 5.0,
              borderRadius: BorderRadius.circular(8),
              child: GooglePlaceAutoCompleteTextField(
                textEditingController: _searchController,
                googleAPIKey: 'AIzaSyBukfII7TCZPVkPCk49PG4du-7GlQ7YLcs',
                inputDecoration: const InputDecoration(
                  hintText: 'Search location',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(15),
                ),
                debounceTime: 800,
                isLatLngRequired: true,
                getPlaceDetailWithLatLng: (prediction) {
                  setState(() {
                    _selectedLocation = LatLng(
                      double.parse(prediction.lat!),
                      double.parse(prediction.lng!),
                    );
                  });
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLng(_selectedLocation),
                  );
                },
                itemClick: (prediction) {
                  _searchController.text = prediction.description!;
                  _searchController.selection = TextSelection.fromPosition(
                    TextPosition(offset: prediction.description!.length),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context, _selectedLocation);
        },
        child: const Icon(Icons.check),
      ),
    );
  }
}
