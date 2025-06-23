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
      if (!mounted) return;

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

  // MODIFICAT: Această funcție a fost actualizată pentru a schimba layout-ul.
  Widget _buildInfoWindow(Map<String, dynamic> data, String placeId, LatLng position, Size size) {
    final provider = TheProvider.of(context, listen: false);
    final bool isFav = provider.favorites.contains(placeId);

    // Formatarea prețului rămâne la fel.
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
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Column(
        children: [
          // Carousel-ul de imagini și iconițele de sus rămân la fel
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
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
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
              Positioned(
                top: 10,
                left: 14,
                right: 14,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    Row(
                      children: [
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
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _customInfoWindowController.hideInfoWindow!(),
                          child: const MyIconButton(icon: Icons.close, radius: 15),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // MODIFICAT: Secțiunea de informații a fost complet refăcută
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: GestureDetector(
                onTap: () {
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Afișăm titlul locației
                    Text(
                      data["title"] ?? 'Nume Indisponibil',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Afișăm adresa sub titlu
                    Text(
                      data['address'] ?? '',
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Afișăm prețul
                    Text.rich(
                      TextSpan(
                        text: priceText,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        children: const [
                          TextSpan(
                            text: "/noapte", // Am tradus în română
                            style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _moveCameraToFitAllMarkers() async {
    if (markers.isEmpty || googleMapController == null) return;

    if (markers.length == 1) {
      googleMapController!.animateCamera(CameraUpdate.newLatLngZoom(markers.first.position, 14));
      return;
    }

    LatLngBounds bounds;
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
    googleMapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
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
                  SizedBox(
                    height: size.height * 0.77,
                    child: GoogleMap(
                      zoomGesturesEnabled: true,
                      scrollGesturesEnabled: true,
                      rotateGesturesEnabled: true,
                      tiltGesturesEnabled: true,
                      initialCameraPosition: const CameraPosition(
                        target: LatLng(45.9432, 24.9668), // Centrat pe România
                        zoom: 6,
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
              "Hartă", // Am tradus
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
