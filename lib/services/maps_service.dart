import 'dart:convert';
import 'dart:math';

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

  /// Calcula a distância entre dois pontos usando a API do Google Maps
  Future<Map<String, dynamic>?> getDistanceAndDuration(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/distancematrix/json?'
      'origins=$originLat,$originLng&'
      'destinations=$destLat,$destLng&'
      'mode=driving&'
      'units=metric&'
      'key=$googleMapsApiKey',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'OK' && data['rows'].isNotEmpty) {
          final element = data['rows'][0]['elements'][0];
          
          if (element['status'] == 'OK') {
            final distance = element['distance'];
            final duration = element['duration'];
            
            return {
              'distance_text': distance['text'],
              'distance_value': distance['value'], // em metros
              'duration_text': duration['text'],
              'duration_value': duration['value'], // em segundos
              'distance_km': (distance['value'] / 1000).toDouble(),
            };
          }
        }
      }
    } catch (e) {
      debugPrint('Erro ao calcular distância: $e');
    }

    return null;
  }

  /// Calcula distância aproximada usando fórmula de Haversine (fallback)
  double calculateHaversineDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadius = 6371; // Raio da Terra em km

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLng = _degreesToRadians(lng2 - lng1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final double distance = earthRadius * c;

    return distance;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }
}
