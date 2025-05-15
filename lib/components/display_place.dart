import 'package:flutter/material.dart';
import '../models/place_model.dart';

class DisplayPlace extends StatelessWidget {
  final Place place;

  const DisplayPlace({super.key, required this.place}); // 👈 this line is important

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(place.imageUrls.first, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(place.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(place.address),
                Text("\$${place.price}/night"),
                Text("⭐ ${place.rating} (${place.review} reviews)"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
