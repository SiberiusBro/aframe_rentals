import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/place_model.dart';

class DisplayPlace extends StatelessWidget {
  final Place place;
  const DisplayPlace({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    // Determine currency symbol or code for current locale
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
    // Format price value
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
    // Format rating and review count
    double displayRating = place.rating;
    if (place.review == 0) {
      displayRating = 0.0;
    }
    String ratingStr = displayRating.toStringAsFixed(1);
    final String reviewLabel = place.review == 1 ? "review" : "reviews";

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
                if (place.placeTag != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Chip(
                      label: Text(place.placeTag!),
                      avatar: Icon(
                        // Choose the correct icon based on tag
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
