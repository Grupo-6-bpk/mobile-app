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
          debugPrint('RideService: Processando ${ridesJson.length} viagens...');
          
          // Log dos dados de cada viagem para debug
          for (int i = 0; i < ridesJson.length; i++) {
            final ride = ridesJson[i] as Map<String, dynamic>;
            debugPrint('RideService: Viagem $i - ID: ${ride['id']}, totalSeats: ${ride['totalSeats']}, availableSeats: ${ride['availableSeats']}');
          }
          
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
        
        List<Map<String, dynamic>> allRequests = [];
        
        if (responseData is List) {
          allRequests = responseData.cast<Map<String, dynamic>>();
        } else if (responseData is Map<String, dynamic> && responseData.containsKey('requests')) {
          final List<dynamic> requestsJson = responseData['requests'];
          allRequests = requestsJson.cast<Map<String, dynamic>>();
        } else if (responseData is Map<String, dynamic> && responseData.containsKey('rideRequests')) {
          final List<dynamic> requestsJson = responseData['rideRequests'];
          allRequests = requestsJson.cast<Map<String, dynamic>>();
        } else {
          debugPrint('RideService: Resposta com formato inesperado.');
          return [];
        }
        
        debugPrint('RideService: Encontradas ${allRequests.length} solicitações totais.');
        return allRequests; // Retornar todas as solicitações, o filtro será feito na página
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

  static Future<bool> cancelRide(int rideId) async {
    if (!_authService.isAuthenticated) {
      throw Exception('Usuário não autenticado.');
    }

    final url = Uri.parse('$apiUrl/api/rides/$rideId');
    final headers = _authService.getAuthHeaders();

    debugPrint('--- RideService: Cancelando viagem $rideId ---');
    debugPrint('URL: $url');

    try {
      final response = await http.delete(
        url,
        headers: headers,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('--- RideService: Viagem cancelada com sucesso! ---');
        return true;
      } else {
        debugPrint('--- RideService: Erro na resposta da API ---');
        debugPrint('Status Code: ${response.statusCode}');
        debugPrint('Response Body: ${response.body}');
        throw Exception(
            'Falha ao cancelar viagem. Código: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('--- RideService: Exceção na chamada HTTP ---');
      debugPrint('Erro: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getRideRequestsByPassenger(int passengerId) async {
    if (!_authService.isAuthenticated) {
      throw Exception('Usuário não autenticado. Faça o login para ver as solicitações.');
    }

    final url = Uri.parse('$apiUrl/api/ride-requests?passengerId=$passengerId');
    final headers = _authService.getAuthHeaders();

    debugPrint('--- RideService: Buscando solicitações para passageiro $passengerId ---');
    debugPrint('URL: $url');

    try {
      final response = await http.get(
        url,
        headers: headers,
      );

      if (response.statusCode == 200) {
        debugPrint('--- RideService: Sucesso ao buscar solicitações do passageiro! ---');
        final responseData = jsonDecode(response.body);
        
        List<Map<String, dynamic>> allRequests = [];
        
        if (responseData is List) {
          allRequests = responseData.cast<Map<String, dynamic>>();
        } else if (responseData is Map<String, dynamic> && responseData.containsKey('requests')) {
          final List<dynamic> requestsJson = responseData['requests'];
          allRequests = requestsJson.cast<Map<String, dynamic>>();
        } else if (responseData is Map<String, dynamic> && responseData.containsKey('rideRequests')) {
          final List<dynamic> requestsJson = responseData['rideRequests'];
          allRequests = requestsJson.cast<Map<String, dynamic>>();
        } else {
          debugPrint('RideService: Resposta com formato inesperado.');
          return [];
        }
        
        // Filtrar apenas solicitações com status PENDING
        final pendingRequests = allRequests.where((request) {
          final status = request['status']?.toString().toUpperCase();
          return status == 'PENDING' || status == null; // Incluir null como PENDING
        }).toList();
        
        debugPrint('RideService: Encontradas ${allRequests.length} solicitações totais, ${pendingRequests.length} pendentes.');
        return pendingRequests;
      } else {
        debugPrint('--- RideService: Erro na resposta da API ---');
        debugPrint('Status Code: ${response.statusCode}');
        debugPrint('Response Body: ${response.body}');
        throw Exception(
            'Falha ao carregar solicitações do passageiro. Código: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('--- RideService: Exceção na chamada HTTP ---');
      debugPrint('Erro: $e');
      rethrow;
    }
  }

  // Função startRide - implementação para funcionar com o backend
  static Future<bool> startRide(int rideId) async {
    if (!_authService.isAuthenticated) {
      throw Exception('Usuário não autenticado.');
    }

    // Usar PATCH para atualizar o status da viagem
    final url = Uri.parse('$apiUrl/api/rides/$rideId');
    final headers = _authService.getAuthHeaders();
    final body = jsonEncode({
      'status': 'IN_PROGRESS',
    });

    debugPrint('--- RideService: Iniciando viagem $rideId ---');
    debugPrint('URL: $url');
    debugPrint('Body: $body');
    debugPrint('Headers: $headers');

    try {
      final response = await http.patch(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('--- RideService: Viagem iniciada com sucesso! ---');
        return true;
      } else {
        debugPrint('--- RideService: Erro na resposta da API ---');
        debugPrint('Status Code: ${response.statusCode}');
        debugPrint('Response Body: ${response.body}');
        
        // Se PATCH não funcionar, tentar com PUT
        debugPrint('--- RideService: Tentando com PUT ---');
        final putResponse = await http.put(
          url,
          headers: headers,
          body: body,
        );
        
        if (putResponse.statusCode == 200 || putResponse.statusCode == 204) {
          debugPrint('--- RideService: Viagem iniciada com sucesso (PUT)! ---');
          return true;
        } else {
          debugPrint('--- RideService: Erro com PUT ---');
          debugPrint('Status Code: ${putResponse.statusCode}');
          debugPrint('Response Body: ${putResponse.body}');
          throw Exception(
              'Falha ao iniciar viagem. Código: ${putResponse.statusCode}');
        }
      }
    } catch (e) {
      debugPrint('--- RideService: Exceção na chamada HTTP ---');
      debugPrint('Erro: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getRideById(int rideId) async {
    if (!_authService.isAuthenticated) {
      throw Exception('Usuário não autenticado.');
    }
    final url = Uri.parse('$apiUrl/api/rides/$rideId');
    final headers = _authService.getAuthHeaders();
    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData is Map<String, dynamic>) {
          return responseData;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Método utilitário para validar e extrair o rideId de forma consistente
  static int? extractRideId(dynamic data) {
    if (data == null) return null;
    
    // Se data é um Map, tentar extrair rideId
    if (data is Map<String, dynamic>) {
      final rideId = data['rideId'] ?? data['id'] ?? data['ride_id'];
      if (rideId != null) {
        return rideId is int ? rideId : int.tryParse(rideId.toString());
      }
    }
    
    // Se data é um número, retornar diretamente
    if (data is int) return data;
    
    // Se data é uma string, tentar converter para int
    if (data is String) {
      return int.tryParse(data);
    }
    
    return null;
  }

  /// Método utilitário para validar se o rideId está presente e é válido
  static bool isValidRideId(dynamic rideId) {
    if (rideId == null) return false;
    
    if (rideId is int) return rideId > 0;
    if (rideId is String) {
      final parsed = int.tryParse(rideId);
      return parsed != null && parsed > 0;
    }
    
    return false;
  }
} 