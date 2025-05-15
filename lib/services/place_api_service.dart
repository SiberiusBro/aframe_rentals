import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/place_model.dart';

class PlaceApiService {
  static const String baseUrl = 'http://10.0.2.2:5000'; // update this later

  Future<List<Place>> getAllPlaces() async {
    final response = await http.get(Uri.parse('$baseUrl/places'));

    if (response.statusCode == 200) {
      List jsonData = jsonDecode(response.body);
      return jsonData.map((json) => Place.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load places');
    }
  }

  Future<void> createPlace(Place place) async {
    final response = await http.post(
      Uri.parse('$baseUrl/places'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(place.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create place');
    }
  }
}
