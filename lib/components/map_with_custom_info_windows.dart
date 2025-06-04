//components/map_with_custom_info_windows.dart
import 'package:aframe_rentals/components/my_icon_button.dart';
import 'package:another_carousel_pro/another_carousel_pro.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:custom_info_window/custom_info_window.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:aframe_rentals/models/place_model.dart';
import 'package:aframe_rentals/screens/place_detail_screen.dart';
import 'package:aframe_rentals/services/the_provider.dart';

class MapWithCustomInfoWindows extends StatefulWidget {
  const MapWithCustomInfoWindows({super.key});

  @override
  State<MapWithCustomInfoWindows> createState() => _MapWithCustomInfoWindowsState();
}

class _MapWithCustomInfoWindowsState extends State<MapWithCustomInfoWindows> {
  final CustomInfoWindowController _customInfoWindowController = CustomInfoWindowController();
  final CollectionReference placeCollection = FirebaseFirestore.instance.collection("places");

  List<Marker> markers = [];
  GoogleMapController? googleMapController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadMarkers();
  }

  Future<void> _loadMarkers() async {
    final Size size = MediaQuery.of(context).size;
    placeCollection.where('isActive', isEqualTo: true).snapshots().listen((snapshot) {
      if (snapshot.docs.isEmpty) return;
      final List<Marker> newMarkers = [];
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final LatLng latLng = LatLng(data['latitude'], data['longitude']);
        final String placeId = doc.id;
        newMarkers.add(
          Marker(
            markerId: MarkerId(placeId),
            position: latLng,
            onTap: () {
              _customInfoWindowController.addInfoWindow!(
                _buildInfoWindow(data, placeId, latLng, size),
                latLng,
              );
            },
            icon: BitmapDescriptor.defaultMarker,
          ),
        );
      }
      setState(() {
        markers = newMarkers;
      });
      _moveCameraToFitAllMarkers();
    });
  }

  Widget _buildInfoWindow(Map<String, dynamic> data, String placeId, LatLng position, Size size) {
    final provider = TheProvider.of(context, listen: false);
    final bool isFav = provider.favorites.contains(placeId);
    // Rating and review count
    double rating = (data['rating'] ?? 0).toDouble();
    final int reviewCount = data['review'] ?? 0;
    if (reviewCount == 0) {
      rating = 0.0;
    }
    // Currency formatting for price
    Locale locale = Localizations.localeOf(context);
    String countryCode = locale.countryCode ?? 'US';
    String currencySymbol;
    if (countryCode == 'RO') {
      currencySymbol = '';
    } else if (countryCode == 'GB') {
      currencySymbol = '£';
    } else if (countryCode == 'US' || countryCode == 'AU' || countryCode == 'CA' || countryCode == 'NZ') {
      currencySymbol = '\$';
    } else if (['AT','BE','CY','EE','FI','FR','DE','GR','IE','IT','LV','LT','LU','MT','NL','PT','SK','SI','ES'].contains(countryCode)) {
      currencySymbol = '€';
    } else {
      currencySymbol = NumberFormat.simpleCurrency(locale: locale.toString()).currencySymbol;
    }
    String priceStr = (data['price'] ?? '').toString();
    if (priceStr.endsWith('.0')) {
      priceStr = priceStr.substring(0, priceStr.length - 2);
    }
    late String priceText;
    if (countryCode == 'RO') {
      priceText = "$priceStr RON";
    } else if (RegExp(r'^[A-Za-z]+$').hasMatch(currencySymbol)) {
      priceText = "$priceStr $currencySymbol";
    } else {
      priceText = "$currencySymbol$priceStr";
    }

    return Container(
      height: size.height * 0.32,
      width: size.width * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          // Image carousel with icons
          Stack(
            children: [
              SizedBox(
                height: size.height * 0.203,
                width: size.width * 0.8,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                  child: AnotherCarousel(
                    images: (data['imageUrls'] as List).map((url) => NetworkImage(url)).toList(),
                    dotSize: 5,
                    indicatorBgPadding: 5,
                    dotBgColor: Colors.transparent,
                  ),
                ),
              ),
              // Open details on image tap
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context); // close map bottom sheet
                    final placeMap = Map<String, dynamic>.from(data);
                    placeMap['id'] = placeId;
                    final place = Place.fromJson(placeMap);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PlaceDetailScreen(place: place)),
                    );
                  },
                  child: Container(color: Colors.transparent),
                ),
              ),
              // Top row with favorite and close icons
              Positioned(
                top: 10,
                left: 14,
                right: 14,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        "Guest Favorite",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () async {
                        await provider.toggleFavoriteById(placeId);
                        _customInfoWindowController.addInfoWindow!(
                          _buildInfoWindow(data, placeId, position, size),
                          position,
                        );
                      },
                      child: MyIconButton(
                        icon: isFav ? Icons.favorite : Icons.favorite_border,
                        radius: 15,
                      ),
                    ),
                    const SizedBox(width: 13),
                    InkWell(
                      onTap: () => _customInfoWindowController.hideInfoWindow!(),
                      child: const MyIconButton(icon: Icons.close, radius: 15),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Place summary info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                final placeMap = Map<String, dynamic>.from(data);
                placeMap['id'] = placeId;
                final place = Place.fromJson(placeMap);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PlaceDetailScreen(place: place)),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        data["address"] ?? '',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      const Icon(Icons.star, color: Colors.black54),
                      const SizedBox(width: 5),
                      Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  Text(
                    "$reviewCount reviews",
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  Text(
                    data['date'] ?? '',
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  Text.rich(
                    TextSpan(
                      text: priceText,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      children: const [
                        TextSpan(
                          text: "/night",
                          style: TextStyle(fontWeight: FontWeight.normal),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _moveCameraToFitAllMarkers() async {
    if (markers.isEmpty) return;
    LatLngBounds bounds;
    if (markers.length == 1) {
      final pos = markers.first.position;
      bounds = LatLngBounds(southwest: pos, northeast: pos);
    } else {
      final latitudes = markers.map((m) => m.position.latitude).toList();
      final longitudes = markers.map((m) => m.position.longitude).toList();
      bounds = LatLngBounds(
        southwest: LatLng(
          latitudes.reduce((a, b) => a < b ? a : b),
          longitudes.reduce((a, b) => a < b ? a : b),
        ),
        northeast: LatLng(
          latitudes.reduce((a, b) => a > b ? a : b),
          longitudes.reduce((a, b) => a > b ? a : b),
        ),
      );
    }
    await googleMapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      backgroundColor: Colors.transparent,
      elevation: 0,
      onPressed: () {
        showModalBottomSheet(
          clipBehavior: Clip.none,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          context: context,
          builder: (BuildContext context) {
            final Size size = MediaQuery.of(context).size;
            return Container(
              color: Colors.white,
              height: size.height * 0.77,
              width: size.width,
              child: Stack(
                children: [
                  // Map
                  SizedBox(
                    height: size.height * 0.77,
                    child: GoogleMap(
                      zoomGesturesEnabled: true,
                      scrollGesturesEnabled: true,
                      rotateGesturesEnabled: true,
                      tiltGesturesEnabled: true,
                      initialCameraPosition: const CameraPosition(
                        target: LatLng(0, 0),
                        zoom: 1,
                      ),
                      onMapCreated: (controller) {
                        googleMapController = controller;
                        _customInfoWindowController.googleMapController = controller;
                        _moveCameraToFitAllMarkers();
                      },
                      onTap: (_) => _customInfoWindowController.hideInfoWindow!(),
                      onCameraMove: (_) => _customInfoWindowController.onCameraMove!(),
                      markers: markers.toSet(),
                    ),
                  ),
                  // Custom info window overlay
                  CustomInfoWindow(
                    controller: _customInfoWindowController,
                    height: size.height * 0.34,
                    width: size.width * 0.85,
                    offset: 50,
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 170, vertical: 5),
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
        child: const Row(
          children: [
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
