import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/background_container.dart';

class CabinDetailScreen extends StatelessWidget {
  final Map cabinData;

  const CabinDetailScreen({super.key, required this.cabinData});

  // Opens Google Maps with directions to the cabin’s coordinates.
  void _openNavigation(BuildContext context) async {
    final double latitude = cabinData['latitude'] is double
        ? cabinData['latitude']
        : double.tryParse(cabinData['latitude'].toString()) ?? 0.0;
    final double longitude = cabinData['longitude'] is double
        ? cabinData['longitude']
        : double.tryParse(cabinData['longitude'].toString()) ?? 0.0;
    final String googleMapsUrl =
        'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude';

    if (await canLaunch(googleMapsUrl)) {
      await launch(googleMapsUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the map.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Retrieve fields from cabinData.
    final String title = cabinData['title'] ?? 'Cabin';
    final double price = cabinData['price'] is double
        ? cabinData['price']
        : double.tryParse(cabinData['price'].toString()) ?? 0.0;
    final String imageUrl = cabinData['imageUrl'] ?? '';
    final String description = cabinData['description'] ??
        'A beautiful cabin for rent. Enjoy the serenity and comfort with all modern amenities.';

    // Extra facilities: expect cabinData['extras'] to be a List of maps.
    final List<dynamic> extras = cabinData['extras'] is List
        ? cabinData['extras'] as List<dynamic>
        : [];

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: BackgroundContainer(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabin Image
                imageUrl.isNotEmpty
                    ? Image.network(
                  imageUrl,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
                    : Container(
                  height: 250,
                  width: double.infinity,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                // Title and Price Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    Text(
                      "\$$price / night",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Description
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                // Extra Facilities Section
                if (extras.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Possible Extra Facilities:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // For each extra facility, display its name and extra price.
                      ...extras.map((facility) {
                        final String facilityName =
                            facility['name']?.toString() ?? 'Facility';
                        final double facilityPrice =
                        facility['price'] is double
                            ? facility['price']
                            : double.tryParse(
                            facility['price']?.toString() ?? '0') ??
                            0.0;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            facilityName,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          trailing: Text(
                            '+ \$${facilityPrice.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                const SizedBox(height: 20),
                // "Take me there" button
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => _openNavigation(context),
                    icon: const Icon(Icons.navigation),
                    label: const Text("Take me there"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
