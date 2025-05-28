import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:custom_info_window/custom_info_window.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aframe_rentals/models/place_model.dart';
import 'package:aframe_rentals/screens/place_detail_screen.dart';
import 'package:another_carousel_pro/another_carousel_pro.dart';
import 'package:aframe_rentals/components/my_icon_button.dart';
import 'dart:async';


class MapWithCustomInfoWindows extends StatefulWidget {
  const MapWithCustomInfoWindows({Key? key}) : super(key: key);

  @override
  State<MapWithCustomInfoWindows> createState() => _MapWithCustomInfoWindowsState();
}

class _MapWithCustomInfoWindowsState extends State<MapWithCustomInfoWindows> {
  final CustomInfoWindowController _customInfoWindowController = CustomInfoWindowController();
  GoogleMapController? _googleMapController;
  StreamSubscription<QuerySnapshot>? _placesSubscription;
  List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    // Listen to Firestore "places" collection (only active places) and build markers
    _placesSubscription = FirebaseFirestore.instance
        .collection('places')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return; // ensure widget is still mounted
      if (snapshot.docs.isEmpty) {
        setState(() => _markers = []);
        return;
      }
      // Build markers list from snapshot
      final List<Marker> markerList = [];
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;                   // ensure ID is included
        final place = Place.fromJson(data);    // construct Place with safe defaults
        final position = LatLng(place.latitude, place.longitude);
        // Only add marker if coordinates are valid (non-zero)
        if (place.latitude == 0 && place.longitude == 0) {
          continue; // skip places with no location
        }
        markerList.add(
          Marker(
            markerId: MarkerId(place.id ?? doc.id),
            position: position,
            onTap: () {
              // When marker tapped, show custom info window
              final Size infoSize = MediaQuery.of(context).size;
              _customInfoWindowController.addInfoWindow!(
                GestureDetector(
                  onTap: () {
                    // Navigate to detail page for this place
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PlaceDetailScreen(place: place)),
                    );
                  },
                  child: Container(
                    height: infoSize.height * 0.32,
                    width: infoSize.width * 0.8,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Column(
                      children: [
                        // Image carousel with favorite & close buttons overlay
                        Stack(
                          children: [
                            SizedBox(
                              height: infoSize.height * 0.203,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(25),
                                  topRight: Radius.circular(25),
                                ),
                                child: AnotherCarousel(
                                  images: place.imageUrls.isNotEmpty
                                      ? place.imageUrls.map((url) => NetworkImage(url)).toList()
                                      : [const NetworkImage('https://via.placeholder.com/400?text=No+Image')],
                                  dotSize: 5,
                                  indicatorBgPadding: 5,
                                  dotBgColor: Colors.transparent,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 10,
                              left: 0,
                              right: 0,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // Favorite icon (not functional yet, just UI)
                                    MyIconButton(icon: Icons.favorite_border, radius: 15),
                                    const SizedBox(width: 13),
                                    // Close button to hide the info window
                                    InkWell(
                                      onTap: () => _customInfoWindowController.hideInfoWindow!(),
                                      child: MyIconButton(icon: Icons.close, radius: 15),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Info text section: title, rating, and price
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      place.title,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (place.rating != 0) ...[
                                    const Icon(Icons.star, color: Colors.orange, size: 16),
                                    const SizedBox(width: 5),
                                    Text(place.rating.toStringAsFixed(1)),
                                  ],
                                ],
                              ),
                              // Price per night
                              Text.rich(
                                TextSpan(
                                  text: '\$${place.price}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  children: const [
                                    TextSpan(
                                      text: " night",
                                      style: TextStyle(fontWeight: FontWeight.normal),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                position,
              );
            },
          ),
        );
      }
      setState(() {
        _markers = markerList;
      });
      // Adjust camera bounds if map is already initialized
      if (_googleMapController != null && _markers.isNotEmpty) {
        _moveCameraToFitAllMarkers();
      }
    });
  }

  Future<void> _moveCameraToFitAllMarkers() async {
    if (_markers.isEmpty || _googleMapController == null) return;
    // Calculate bounding box for all marker positions
    late LatLngBounds bounds;
    if (_markers.length == 1) {
      final pos = _markers.first.position;
      bounds = LatLngBounds(southwest: pos, northeast: pos);
    } else {
      double minLat = double.infinity, maxLat = -double.infinity;
      double minLng = double.infinity, maxLng = -double.infinity;
      for (var marker in _markers) {
        final lat = marker.position.latitude;
        final lng = marker.position.longitude;
        if (lat < minLat) minLat = lat;
        if (lat > maxLat) maxLat = lat;
        if (lng < minLng) minLng = lng;
        if (lng > maxLng) maxLng = lng;
      }
      bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );
    }
    try {
      await _googleMapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    } catch (e) {
      // In case bounds calculation fails (e.g., for identical points), fall back to single point
      if (_markers.isNotEmpty) {
        await _googleMapController!.animateCamera(CameraUpdate.newLatLng(_markers.first.position));
      }
    }
  }

  @override
  void dispose() {
    _placesSubscription?.cancel();
    _customInfoWindowController.dispose();
    _googleMapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      backgroundColor: Colors.transparent,
      elevation: 0,
      onPressed: () {
        // Open a bottom sheet containing the Google Map
        final size = MediaQuery.of(context).size;
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) {
            return Container(
              color: Colors.white,
              height: size.height * 0.77,
              width: size.width,
              child: Stack(
                children: [
                  // Google Map with markers
                  GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(0, 0), // will be updated to fit markers
                      zoom: 1,
                    ),
                    markers: _markers.toSet(),
                    zoomGesturesEnabled: true,
                    scrollGesturesEnabled: true,
                    rotateGesturesEnabled: true,
                    tiltGesturesEnabled: true,
                    onMapCreated: (controller) {
                      _googleMapController = controller;
                      _customInfoWindowController.googleMapController = controller;
                      _moveCameraToFitAllMarkers(); // focus map on markers when opened
                    },
                    onTap: (_) => _customInfoWindowController.hideInfoWindow!(),
                    onCameraMove: (_) => _customInfoWindowController.onCameraMove!(),
                  ),
                  // Custom info window overlay
                  CustomInfoWindow(
                    controller: _customInfoWindowController,
                    height: size.height * 0.34,
                    width: size.width * 0.85,
                    offset: 50,
                  ),
                  // Drag handle / tap area to close the bottom sheet
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 170.0),
                      child: Container(
                        height: 5,
                        width: 50,
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      label: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: const [
            SizedBox(width: 5),
            Text(
              "Map",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(width: 5),
            Icon(Icons.map_outlined, color: Colors.white),
            SizedBox(width: 5),
          ],
        ),
      ),
    );
  }
}
