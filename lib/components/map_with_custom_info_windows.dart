import 'package:aframe_rentals/components/my_icon_button.dart';
import 'package:another_carousel_pro/another_carousel_pro.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:custom_info_window/custom_info_window.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapWithCustomInfoWindows extends StatefulWidget {
  const MapWithCustomInfoWindows({super.key});

  @override
  State<MapWithCustomInfoWindows> createState() => _MapWithCustomInfoWindowsState();
}

class _MapWithCustomInfoWindowsState extends State<MapWithCustomInfoWindows> {
  final CustomInfoWindowController _customInfoWindowController = CustomInfoWindowController();
  final CollectionReference placeCollection = FirebaseFirestore.instance.collection("places");

  List<Marker> markers = [];
  late GoogleMapController googleMapController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadMarkers(); // <- uses MediaQuery here
  }

  Future<void> _loadMarkers() async {
    Size size = MediaQuery.of(context).size;

    placeCollection.snapshots().listen((QuerySnapshot streamSnapshot) {
      if (streamSnapshot.docs.isEmpty) return;

      final List<Marker> myMarker = [];

      for (final marker in streamSnapshot.docs) {
        final data = marker.data() as Map<String, dynamic>;
        final latLng = LatLng(data['latitude'], data['longitude']);

        myMarker.add(
          Marker(
            markerId: MarkerId(data['address']),
            position: latLng,
            onTap: () {
              _customInfoWindowController.addInfoWindow!(
                Container(
                  height: size.height * 0.32,
                  width: size.width * 0.8,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          SizedBox(
                            height: size.height * 0.203,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(25),
                                topRight: Radius.circular(25),
                              ),
                              child: AnotherCarousel(
                                images: data['imageUrls']
                                    .map<NetworkImage>((url) => NetworkImage(url))
                                    .toList(),
                                dotSize: 5,
                                indicatorBgPadding: 5,
                                dotBgColor: Colors.transparent,
                              ),
                            ),
                          ),
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
                                const MyIconButton(icon: Icons.favorite_border, radius: 15),
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  data["address"],
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                const Icon(Icons.star),
                                const SizedBox(width: 5),
                                Text(data['rating'].toString()),
                              ],
                            ),
                            const Text(
                              "3066 m elevation",
                              style: TextStyle(fontSize: 16, color: Colors.black54),
                            ),
                            Text(
                              data['date'],
                              style: const TextStyle(fontSize: 16, color: Colors.black54),
                            ),
                            Text.rich(
                              TextSpan(
                                text: '\$${data['price']}',
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
                latLng,
              );
            },
            icon: BitmapDescriptor.defaultMarker,
          ),
        );
      }

      setState(() {
        markers = myMarker;
      });

      _moveCameraToFitAllMarkers();
    });
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

    await googleMapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
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
                        target: LatLng(0, 0), // placeholder, will auto-focus later
                        zoom: 1,
                      ),
                      onMapCreated: (GoogleMapController controller) {
                        googleMapController = controller;
                        _customInfoWindowController.googleMapController = controller;
                        _moveCameraToFitAllMarkers(); // refocus on open
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
              "Map",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
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
