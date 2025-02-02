import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('A-Frame Rentals'),
      ),
      body: ListView(
        children: [
          // We'll add A-Frame listings here later
          ListTile(
            title: const Text('Beautiful A-Frame Cabin'),
            subtitle: const Text('\$150 per night'),
            leading: Image.network(
              'https://via.placeholder.com/150', // Placeholder image
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
            onTap: () {
              // Navigate to property details later
            },
          ),
        ],
      ),
    );
  }
}