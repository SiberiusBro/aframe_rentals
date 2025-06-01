import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/place_model.dart';
import 'package:provider/provider.dart';
import '../services/the_provider.dart';

class DisplayPlace extends StatelessWidget {
  final Place place;
  const DisplayPlace({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    Locale locale = Localizations.localeOf(context);
    String countryCode = locale.countryCode ?? 'US';
    String currencySymbol;
    if (countryCode == 'RO') {
      currencySymbol = '';
    } else if (countryCode == 'GB') {
      currencySymbol = '£';
    } else if (countryCode == 'US' || countryCode == 'AU' || countryCode == 'CA' || countryCode == 'NZ') {
      currencySymbol = '\$';
    } else if ([
      'AT',
      'BE',
      'CY',
      'EE',
      'FI',
      'FR',
      'DE',
      'GR',
      'IE',
      'IT',
      'LV',
      'LT',
      'LU',
      'MT',
      'NL',
      'PT',
      'SK',
      'SI',
      'ES'
    ].contains(countryCode)) {
      currencySymbol = '€';
    } else {
      currencySymbol = NumberFormat.simpleCurrency(locale: locale.toString()).currencySymbol;
    }
    String priceStr = place.price.toString();
    if (priceStr.endsWith('.0')) {
      priceStr = priceStr.substring(0, priceStr.length - 2);
    }
    late String priceDisplay;
    if (countryCode == 'RO') {
      priceDisplay = "$priceStr RON";
    } else if (RegExp(r'^[A-Za-z]+$').hasMatch(currencySymbol)) {
      priceDisplay = "$priceStr $currencySymbol";
    } else {
      priceDisplay = "$currencySymbol$priceStr";
    }
    double displayRating = place.rating;
    if (place.review == 0) {
      displayRating = 0.0;
    }
    String ratingStr = displayRating.toStringAsFixed(1);
    final String reviewLabel = place.review == 1 ? "review" : "reviews";

    // Use provider for wishlist logic
    final provider = TheProvider.of(context);
    final isFav = provider.isFavorite(place.id!);

    return Card(
      margin: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Image.network(place.imageUrls.first, fit: BoxFit.cover, width: double.infinity, height: 180),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? Colors.red : Colors.grey,
                  ),
                  onPressed: () async {
                    await provider.toggleFavoriteById(place.id!);
                  },
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(place.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(place.address),
                if (place.placeTag != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Chip(
                      label: Text(place.placeTag!),
                      avatar: Icon(
                        place.placeTag == 'Beach'
                            ? Icons.beach_access
                            : place.placeTag == 'Mountain'
                            ? Icons.terrain
                            : place.placeTag == 'Rural'
                            ? Icons.grass
                            : Icons.location_city,
                        size: 16,
                      ),
                    ),
                  ),
                ],
                // Facilities chips
                if (place.facilities != null && place.facilities!.containsValue(true))
                  Wrap(
                    spacing: 6,
                    children: place.facilities!.entries.where((e) => e.value).map((entry) {
                      return Chip(
                        label: Text(entry.key),
                        avatar: Icon(
                          entry.key == 'Wifi'
                              ? Icons.wifi
                              : entry.key == 'Room Temperature Control'
                              ? Icons.thermostat
                              : Icons.check,
                          size: 16,
                        ),
                      );
                    }).toList(),
                  ),
                Text("$priceDisplay/night"),
                Text("⭐ $ratingStr (${place.review} $reviewLabel)"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
