import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/config/app_config.dart';
import 'package:mobile_app/models/ride.dart';
import 'package:flutter/foundation.dart';

class RideService {
  static final String apiUrl = AppConfig.baseUrl;
  static final AuthService _authService = AuthService();
  final user = _authService.currentUser;

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

  static Future<List<Map<String, dynamic>>> getRideRequests(int rideId) async {
    if (!_authService.isAuthenticated) {
      throw Exception('Usuário não autenticado. Faça o login para ver as solicitações.');
    }

    final url = Uri.parse('$apiUrl/api/rides/$rideId/requests');
    final headers = _authService.getAuthHeaders();

    debugPrint('--- RideService: Buscando solicitações para ride $rideId ---');
    debugPrint('URL: $url');

    try {
      final response = await http.get(
        url,
        headers: headers,
      );

      if (response.statusCode == 200) {
        debugPrint('--- RideService: Sucesso ao buscar solicitações! ---');
        final responseData = jsonDecode(response.body);
        
        if (responseData is List) {
          final List<Map<String, dynamic>> requests = responseData.cast<Map<String, dynamic>>();
          debugPrint('RideService: Encontradas ${requests.length} solicitações.');
          return requests;
        } else if (responseData is Map<String, dynamic> && responseData.containsKey('requests')) {
          final List<dynamic> requestsJson = responseData['requests'];
          final requests = requestsJson.cast<Map<String, dynamic>>();
          debugPrint('RideService: Encontradas ${requests.length} solicitações.');
          return requests;
        } else {
          debugPrint('RideService: Resposta com formato inesperado.');
          return [];
        }
      } else {
        debugPrint('--- RideService: Erro na resposta da API ---');
        debugPrint('Status Code: ${response.statusCode}');
        debugPrint('Response Body: ${response.body}');
        throw Exception(
            'Falha ao carregar solicitações. Código: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('--- RideService: Exceção na chamada HTTP ---');
      debugPrint('Erro: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getRideRequestsByDriver(int driverId) async {
    if (!_authService.isAuthenticated) {
      throw Exception('Usuário não autenticado. Faça o login para ver as solicitações.');
    }

    final url = Uri.parse('$apiUrl/api/ride-requests?driverId=$driverId');
    final headers = _authService.getAuthHeaders();

    debugPrint('--- RideService: Buscando solicitações para motorista $driverId ---');
    debugPrint('URL: $url');

    try {
      final response = await http.get(
        url,
        headers: headers,
      );

      if (response.statusCode == 200) {
        debugPrint('--- RideService: Sucesso ao buscar solicitações do motorista! ---');
        final responseData = jsonDecode(response.body);
        
        if (responseData is List) {
          final List<Map<String, dynamic>> requests = responseData.cast<Map<String, dynamic>>();
          debugPrint('RideService: Encontradas ${requests.length} solicitações para o motorista.');
          return requests;
        } else if (responseData is Map<String, dynamic> && responseData.containsKey('requests')) {
          final List<dynamic> requestsJson = responseData['requests'];
          final requests = requestsJson.cast<Map<String, dynamic>>();
          debugPrint('RideService: Encontradas ${requests.length} solicitações para o motorista.');
          return requests;
        } else if (responseData is Map<String, dynamic> && responseData.containsKey('rideRequests')) {
          final List<dynamic> requestsJson = responseData['rideRequests'];
          final requests = requestsJson.cast<Map<String, dynamic>>();
          debugPrint('RideService: Encontradas ${requests.length} solicitações para o motorista.');
          return requests;
        } else {
          debugPrint('RideService: Resposta com formato inesperado.');
          return [];
        }
      } else {
        debugPrint('--- RideService: Erro na resposta da API ---');
        debugPrint('Status Code: ${response.statusCode}');
        debugPrint('Response Body: ${response.body}');
        throw Exception(
            'Falha ao carregar solicitações do motorista. Código: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('--- RideService: Exceção na chamada HTTP ---');
      debugPrint('Erro: $e');
      rethrow;
    }
  }

  static Future<bool> updateRideRequestStatus(int requestId, String status) async {
    if (!_authService.isAuthenticated) {
      throw Exception('Usuário não autenticado.');
    }

    final url = Uri.parse('$apiUrl/api/ride-requests/$requestId/status');
    final headers = _authService.getAuthHeaders();
    final body = jsonEncode({
      'status': status,
    });

    debugPrint('--- RideService: Atualizando status da solicitação $requestId para $status ---');
    debugPrint('URL: $url');
    debugPrint('Body: $body');

    try {
      final response = await http.patch(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('--- RideService: Status da solicitação atualizado com sucesso! ---');
        return true;
      } else {
        debugPrint('--- RideService: Erro na resposta da API ---');
        debugPrint('Status Code: ${response.statusCode}');
        debugPrint('Response Body: ${response.body}');
        throw Exception(
            'Falha ao atualizar status da solicitação. Código: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('--- RideService: Exceção na chamada HTTP ---');
      debugPrint('Erro: $e');
      rethrow;
    }
  }

  static Future<int?> getLatestRideByDriver(int driverId) async {
    if (!_authService.isAuthenticated) {
      throw Exception('Usuário não autenticado.');
    }

    final url = Uri.parse('$apiUrl/api/rides?driverId=$driverId&limit=1&sort=createdAt:desc');
    final headers = _authService.getAuthHeaders();

    debugPrint('--- RideService: Buscando última viagem do motorista $driverId ---');
    debugPrint('URL: $url');

    try {
      final response = await http.get(
        url,
        headers: headers,
      );

      if (response.statusCode == 200) {
        debugPrint('--- RideService: Sucesso ao buscar última viagem! ---');
        final responseData = jsonDecode(response.body);
        
        if (responseData is Map<String, dynamic> && responseData.containsKey('rides')) {
          final List<dynamic> ridesJson = responseData['rides'];
          if (ridesJson.isNotEmpty) {
            final latestRide = ridesJson.first as Map<String, dynamic>;
            final rideId = latestRide['id'] ?? latestRide['rideId'];
            debugPrint('RideService: Última viagem encontrada com ID: $rideId');
            return rideId is int ? rideId : int.tryParse(rideId.toString());
          }
        } else if (responseData is List && responseData.isNotEmpty) {
          final latestRide = responseData.first as Map<String, dynamic>;
          final rideId = latestRide['id'] ?? latestRide['rideId'];
          debugPrint('RideService: Última viagem encontrada com ID: $rideId');
          return rideId is int ? rideId : int.tryParse(rideId.toString());
        }
        
        debugPrint('RideService: Nenhuma viagem encontrada para o motorista.');
        return null;
      } else {
        debugPrint('--- RideService: Erro na resposta da API ---');
        debugPrint('Status Code: ${response.statusCode}');
        debugPrint('Response Body: ${response.body}');
        throw Exception(
            'Falha ao buscar última viagem. Código: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('--- RideService: Exceção na chamada HTTP ---');
      debugPrint('Erro: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getActiveRideForDriver(int driverId) async {
    if (!_authService.isAuthenticated) {
      throw Exception('Usuário não autenticado.');
    }

    // Busca pela última viagem pendente do motorista
    final url = Uri.parse('$apiUrl/api/rides?driverId=$driverId&status=PENDING&limit=1&sort=createdAt:desc');
    final headers = _authService.getAuthHeaders();

    debugPrint('--- RideService: Buscando viagem ativa para o motorista $driverId ---');
    debugPrint('URL: $url');

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData is Map<String, dynamic> && (responseData['rides'] as List).isNotEmpty) {
          final ride = (responseData['rides'] as List).first;
          debugPrint('--- RideService: Viagem ativa encontrada: ${ride['id']} ---');
          return ride as Map<String, dynamic>;
        } else {
          debugPrint('--- RideService: Nenhuma viagem ativa encontrada. ---');
          return null;
        }
      } else {
        throw Exception('Falha ao buscar viagem ativa. Código: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('--- RideService: Exceção ao buscar viagem ativa: $e ---');
      rethrow;
    }
  }
} 