import 'package:aframe_rentals/models/place_model.dart';
import 'package:flutter/material.dart';
import 'package:another_carousel_pro/another_carousel_pro.dart';
import '../components/location_in_map.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../components/review_prompt.dart';
import '../components/star_rating.dart';
import '../components/review_tile.dart';
import 'booking_screen.dart'; // ✅ Required for navigation

class PlaceDetailScreen extends StatelessWidget {
  final Place place;
  const PlaceDetailScreen({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 120), // ✅ Fix for scroll
          children: [
            // Carousel
            SizedBox(
              height: size.height * 0.35,
              child: AnotherCarousel(
                images: place.imageUrls.map((url) => NetworkImage(url)).toList(),
                showIndicator: false,
                dotBgColor: Colors.transparent,
                boxFit: BoxFit.cover,
              ),
            ),

            // Details
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.title,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.bed),
                      const SizedBox(width: 6),
                      Text("Beds: ${place.beds}"),
                      const SizedBox(width: 20),
                      const Icon(Icons.shower),
                      const SizedBox(width: 6),
                      Text("Bathrooms: ${place.bathrooms}"),
                    ],
                  ),
                  const Divider(height: 30),

                  const Text("About this place",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  const SizedBox(height: 8),
                  Text(place.description ?? "No description available"),
                  const Divider(height: 30),

                  const Text("Location",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  const SizedBox(height: 8),
                  Text(place.address),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 300,
                    child: LocationInMap(
                      latitude: place.latitude,
                      longitude: place.longitude,
                    ),
                  ),

                  const Divider(height: 30),
                  ReviewPrompt(place: place),
                  const Divider(height: 30),

                  const Text("Reviews",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  const SizedBox(height: 8),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('reviews')
                        .where('placeId', isEqualTo: place.id)
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final reviews = snapshot.data!.docs;
                      if (reviews.isEmpty) {
                        return const Text("No reviews yet.");
                      }

                      return Column(
                        children: reviews.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return ReviewTile(
                            userName: data['userName'] ?? 'User',
                            comment: data['comment'] ?? '',
                            rating: (data['rating'] ?? 0).toDouble(),
                            timestamp: DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now(),
                          );
                        }).toList(),
                      );
                    },
                  )
                ],
              ),
            ),
          ],
        ),
      ),

      bottomSheet: Container(
        height: size.height * 0.1,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: TextSpan(
                text: "\$${place.price} ",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18),
                children: const [
                  TextSpan(
                    text: "night",
                    style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black),
                  )
                ],
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingScreen(place: place),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Reserve"),
            )
          ],
        ),
      ),
    );
  }
}
