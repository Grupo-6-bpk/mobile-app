import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/config/app_config.dart';
import 'package:mobile_app/models/ride.dart';
import 'package:flutter/foundation.dart';

class RideService {
  static final String apiUrl = AppConfig.baseUrl;
  static final AuthService _authService = AuthService();

  static Future<bool> createRide({
    required String startLocation,
    required String endLocation,
    required double distance,
    required String departureTime,
    required double fuelPrice,
    required int totalSeats,
    required int driverId,
    required int vehicleId,
  }) async {
    final body = {
      'startLocation': startLocation,
      'endLocation': endLocation,
      'distance': distance,
      'departureTime': departureTime,
      'fuelPrice': fuelPrice,
      'totalSeats': totalSeats,
      'driverId': driverId,
      'vehicleId': vehicleId,
    };

    final response = await http.post(
      Uri.parse('{apiUrl}/api/rides/'),
      headers: _authService.getAuthHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Erro ao criar carona: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<List<Ride>> getRides() async {
    if (!_authService.isAuthenticated) {
      throw Exception('Usuário não autenticado. Faça o login para ver as corridas.');
    }

    final url = Uri.parse('$apiUrl/api/rides');
    final headers = _authService.getAuthHeaders();

    debugPrint('--- RideService: Iniciando busca de corridas ---');
    debugPrint('URL: $url');
    debugPrint('Headers: $headers');

    try {
      final response = await http.get(
        url,
        headers: headers,
      );

      if (response.statusCode == 200) {
        debugPrint('--- RideService: Sucesso! Status 200 ---');
        final responseData = jsonDecode(response.body);
        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('rides') &&
            responseData['rides'] is List) {
          final List<dynamic> ridesJson = responseData['rides'];
          final rides = ridesJson.map((json) => Ride.fromJson(json)).toList();
          debugPrint('RideService: Encontradas ${rides.length} corridas na API.');
          return rides;
        } else {
          debugPrint('RideService: Resposta com formato inesperado.');
          return [];
        }
      } else {
        debugPrint('--- RideService: Erro na resposta da API ---');
        debugPrint('Status Code: ${response.statusCode}');
        debugPrint('Response Body: ${response.body}');
        throw Exception(
            'Falha ao carregar corridas. Código: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('--- RideService: Exceção na chamada HTTP ---');
      debugPrint('Erro: $e');
      rethrow;
    }
  }

  static Future<bool> createRequest(int rideId, int userId) async {
    final body = {
      'userId': userId,
    };

    final response = await http.post(
      Uri.parse('$apiUrl/api/rides/$rideId/requests'),
      headers: _authService.getAuthHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Erro ao criar request de carona: \\${response.statusCode} - \\${response.body}');
    }
  }
} 