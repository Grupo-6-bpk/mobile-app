import 'dart:convert';

import 'package:flutter/rendering.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class MapsService {
  static final String googleMapsApiKey =
      dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  Future<String?> getAddressFromLatLng(double lat, double lng) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$googleMapsApiKey',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['status'] == 'OK') {
        final results = data['results'];
        if (results.isNotEmpty) {
          return results[0]['formatted_address'];
        } else {
          debugPrint('Erro da api: ${data['status']}');
        }
      } else {
        debugPrint('Erro da api: ${data['status']}');
      }
    } else {
      debugPrint('Erro ao buscar endereço: ${response.statusCode}');
    }

    return null;
  }
}
