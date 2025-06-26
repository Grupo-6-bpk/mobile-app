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

  // Cache para evitar requisições desnecessárias
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheDuration = Duration(minutes: 1);

  static String _getCacheKey(String endpoint, Map<String, dynamic>? params) {
    final paramString = params?.entries.map((e) => '${e.key}=${e.value}').join('&') ?? '';
    return '$endpoint?$paramString';
  }

  static bool _isCacheValid(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheDuration;
  }

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
      Uri.parse('$apiUrl/api/rides/'),
      headers: _authService.getAuthHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      // Limpar cache relacionado a rides
      _clearRideCache();
      clearRidesCache(); // Limpar também o novo cache
      return true;
    } else {
      throw Exception('Erro ao criar carona: ${response.statusCode} - ${response.body}');
    }
  }

  static void _clearRideCache() {
    final keysToRemove = _cache.keys.where((key) => key.contains('/rides')).toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  static Future<List<Ride>> getRides({
    bool onlyRecent = true,
    int limitDays = 7,
    int limit = 50,
    String sortBy = 'createdAt:desc',
  }) async {
    if (!_authService.isAuthenticated) {
      throw Exception('Usuário não autenticado. Faça o login para ver as corridas.');
    }

    // Construir parâmetros da URL
    final params = <String, String>{};
    
    if (onlyRecent) {
      // Filtrar corridas dos últimos 'limitDays' dias
      final startDate = DateTime.now().subtract(Duration(days: limitDays));
      params['startDate'] = startDate.toIso8601String();
    }
    
    params['limit'] = limit.toString();
    params['sort'] = sortBy;
    params['status'] = 'PENDING'; // Apenas corridas pendentes (ativas)

    final cacheKey = _getCacheKey('/api/rides', params);
    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey] as List<Ride>;
    }

    // Construir URL com parâmetros
    final uri = Uri.parse('$apiUrl/api/rides').replace(queryParameters: params);
    final headers = _authService.getAuthHeaders();

    if (kDebugMode) {
      debugPrint('🔍 RideService.getRides: Buscando corridas recentes');
      debugPrint('🔍 URL: $uri');
      debugPrint('🔍 Parâmetros: $params');
    }

    try {
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('rides') &&
            responseData['rides'] is List) {
          final List<dynamic> ridesJson = responseData['rides'];
          final rides = ridesJson.map((json) => Ride.fromJson(json)).toList();
          
          // Filtro adicional no frontend para garantir apenas corridas recentes e ativas
          final filteredRides = rides.where((ride) {
            final now = DateTime.now();
            final rideDate = ride.departureTime;
            final statusUpper = ride.status.toUpperCase();
            
            // Apenas corridas PENDING ou que partem no futuro próximo (próximas 24h)
            final isRecentOrFuture = rideDate.isAfter(now.subtract(const Duration(hours: 24)));
            final isActiveStatus = statusUpper == 'PENDING' || statusUpper == 'STARTED';
            
            return isRecentOrFuture && isActiveStatus;
          }).toList();
          
          if (kDebugMode) {
            debugPrint('✅ Total de corridas retornadas pelo backend: ${rides.length}');
            debugPrint('✅ Corridas após filtro local: ${filteredRides.length}');
          }
          
          // Armazenar no cache
          _cache[cacheKey] = filteredRides;
          _cacheTimestamps[cacheKey] = DateTime.now();
          
          return filteredRides;
        } else {
          return [];
        }
      } else {
        throw Exception('Falha ao carregar corridas. Código: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao buscar corridas: $e');
      }
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
      // Limpar cache relacionado a requests
      _clearRequestCache();
      return true;
    } else {
      throw Exception('Erro ao criar request de carona: ${response.statusCode} - ${response.body}');
    }
  }

  static void _clearRequestCache() {
    final keysToRemove = _cache.keys.where((key) => key.contains('/requests')).toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  static Future<List<Map<String, dynamic>>> getRideRequests(int rideId) async {
    if (!_authService.isAuthenticated) {
      throw Exception('Usuário não autenticado. Faça o login para ver as solicitações.');
    }

    final cacheKey = _getCacheKey('/api/rides/$rideId/requests', null);
    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey] as List<Map<String, dynamic>>;
    }

    final url = Uri.parse('$apiUrl/api/rides/$rideId/requests');
    final headers = _authService.getAuthHeaders();

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        List<Map<String, dynamic>> requests = [];
        
        if (responseData is List) {
          requests = responseData.cast<Map<String, dynamic>>();
        } else if (responseData is Map<String, dynamic> && responseData.containsKey('requests')) {
          final List<dynamic> requestsJson = responseData['requests'];
          requests = requestsJson.cast<Map<String, dynamic>>();
        }
        
        // Armazenar no cache
        _cache[cacheKey] = requests;
        _cacheTimestamps[cacheKey] = DateTime.now();
        
        return requests;
      } else {
        throw Exception('Falha ao carregar solicitações. Código: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao buscar solicitações: $e');
      }
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getRideRequestsByDriver(int driverId) async {
    if (!_authService.isAuthenticated) {
      throw Exception('Usuário não autenticado. Faça o login para ver as solicitações.');
    }

    if (kDebugMode) {
      debugPrint('🔍 === INÍCIO getRideRequestsByDriver ===');
      debugPrint('🔍 DriverId: $driverId');
    }

    final cacheKey = _getCacheKey('/api/ride-requests', {'driverId': driverId});
    if (_isCacheValid(cacheKey)) {
      final cachedRequests = _cache[cacheKey] as List<Map<String, dynamic>>;
      if (kDebugMode) {
        debugPrint('✅ Solicitações encontradas no cache: ${cachedRequests.length}');
      }
      return cachedRequests;
    }

    final url = Uri.parse('$apiUrl/api/ride-requests?driverId=$driverId');
    final headers = _authService.getAuthHeaders();

    if (kDebugMode) {
      debugPrint('🔍 URL: $url');
      debugPrint('🔍 Headers: $headers');
    }

    try {
      final response = await http.get(url, headers: headers);

      if (kDebugMode) {
        debugPrint('🔍 Response Status: ${response.statusCode}');
        debugPrint('🔍 Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        List<Map<String, dynamic>> allRequests = [];
        
        if (responseData is List) {
          allRequests = responseData.cast<Map<String, dynamic>>();
          if (kDebugMode) {
            debugPrint('✅ Resposta é uma lista com ${allRequests.length} itens');
          }
        } else if (responseData is Map<String, dynamic> && responseData.containsKey('requests')) {
          final List<dynamic> requestsJson = responseData['requests'];
          allRequests = requestsJson.cast<Map<String, dynamic>>();
          if (kDebugMode) {
            debugPrint('✅ Resposta é um mapa com chave "requests" - ${allRequests.length} itens');
          }
        } else if (responseData is Map<String, dynamic> && responseData.containsKey('rideRequests')) {
          final List<dynamic> requestsJson = responseData['rideRequests'];
          allRequests = requestsJson.cast<Map<String, dynamic>>();
          if (kDebugMode) {
            debugPrint('✅ Resposta é um mapa com chave "rideRequests" - ${allRequests.length} itens');
          }
        } else {
          if (kDebugMode) {
            debugPrint('❌ Formato de resposta não reconhecido');
            debugPrint('❌ Tipo: ${responseData.runtimeType}');
            if (responseData is Map<String, dynamic>) {
              debugPrint('❌ Chaves disponíveis: ${responseData.keys.toList()}');
            }
          }
        }
        
        // Log detalhado das solicitações
        if (kDebugMode && allRequests.isNotEmpty) {
          debugPrint('📋 === SOLICITAÇÕES ENCONTRADAS ===');
          for (int i = 0; i < allRequests.length; i++) {
            final req = allRequests[i];
            debugPrint('  [$i] ID: ${req['id']}, Status: ${req['status']}, RideId: ${req['rideId']}, Passenger: ${req['passenger']?['name']}');
          }
          debugPrint('📋 === FIM SOLICITAÇÕES ===');
        }
        
        // Armazenar no cache
        _cache[cacheKey] = allRequests;
        _cacheTimestamps[cacheKey] = DateTime.now();
        
        if (kDebugMode) {
          debugPrint('✅ Total de solicitações retornadas: ${allRequests.length}');
          debugPrint('🔍 === FIM getRideRequestsByDriver (sucesso) ===');
        }
        
        return allRequests;
      } else if (response.statusCode == 404) {
        if (kDebugMode) {
          debugPrint('ℹ️ Nenhuma solicitação encontrada (404)');
        }
        return [];
      } else {
        if (kDebugMode) {
          debugPrint('❌ Erro HTTP ${response.statusCode}');
          debugPrint('❌ Response: ${response.body}');
        }
        throw Exception('Falha ao carregar solicitações do motorista. Código: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Exceção ao buscar solicitações do motorista: $e');
        debugPrint('🔍 === FIM getRideRequestsByDriver (com erro) ===');
      }
      rethrow;
    }
  }

  static Future<bool> updateRideRequestStatus(int requestId, String status) async {
    if (!_authService.isAuthenticated) {
      throw Exception('Usuário não autenticado.');
    }

    // Validações de entrada
    if (requestId <= 0) {
      throw Exception('ID da solicitação inválido: $requestId');
    }

    // Validar status permitidos
    final allowedStatuses = ['PENDING', 'APPROVED', 'REJECTED', 'CANCELED'];
    final upperStatus = status.toUpperCase();
    if (!allowedStatuses.contains(upperStatus)) {
      throw Exception('Status inválido: $status. Permitidos: ${allowedStatuses.join(', ')}');
    }

    final url = Uri.parse('$apiUrl/api/ride-requests/$requestId/status');
    final headers = _authService.getAuthHeaders();
    
    // Garantir que o Content-Type está correto
    if (!headers.containsKey('Content-Type')) {
      headers['Content-Type'] = 'application/json';
    }
    
    final body = jsonEncode({
      'status': upperStatus, // Usar status em maiúsculo
    });

    if (kDebugMode) {
      debugPrint('--- RideService: Atualizando status da solicitação ---');
      debugPrint('Request ID: $requestId');
      debugPrint('Status original: $status');
      debugPrint('Status normalizado: $upperStatus');
      debugPrint('URL: $url');
      debugPrint('Headers: $headers');
      debugPrint('Body: $body');
    }

    try {
      final response = await http.patch(url, headers: headers, body: body);

      if (kDebugMode) {
        debugPrint('--- RideService: Resposta recebida ---');
        debugPrint('Status Code: ${response.statusCode}');
        debugPrint('Response Body: ${response.body}');
        debugPrint('Response Headers: ${response.headers}');
      }

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Limpar cache relacionado a requests
        _clearRequestCache();
        if (kDebugMode) {
          debugPrint('✅ Status da solicitação atualizado com sucesso!');
        }
        return true;
      } else {
        if (kDebugMode) {
          debugPrint('❌ Erro na resposta da API');
          debugPrint('Status Code: ${response.statusCode}');
          debugPrint('Response Body: ${response.body}');
        }
        
        // Tentar entender melhor o erro 400
        if (response.statusCode == 400) {
          String errorMessage = 'Erro 400 - Requisição inválida';
          try {
            final errorData = jsonDecode(response.body);
            if (errorData is Map<String, dynamic>) {
              errorMessage = errorData['message'] ?? errorData['error'] ?? errorMessage;
              
              // Adicionar detalhes específicos do erro
              if (errorData.containsKey('details')) {
                errorMessage += ' - Detalhes: ${errorData['details']}';
              }
              if (errorData.containsKey('field')) {
                errorMessage += ' - Campo: ${errorData['field']}';
              }
            }
          } catch (e) {
            errorMessage = 'Erro 400: ${response.body}';
          }
          throw Exception(errorMessage);
        }
        
        throw Exception('Falha ao atualizar status da solicitação. Código: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Exceção ao atualizar status da solicitação: $e');
      }
      rethrow;
    }
  }

  static Future<int?> getLatestRideByDriver(int driverId) async {
    if (!_authService.isAuthenticated) {
      throw Exception('Usuário não autenticado.');
    }

    final cacheKey = _getCacheKey('/api/rides', {'driverId': driverId, 'limit': 1, 'sort': 'createdAt:desc'});
    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey] as int?;
    }

    // Filtrar apenas corridas dos últimos 7 dias para evitar confusão
    final startDate = DateTime.now().subtract(const Duration(days: 7));
    final url = Uri.parse('$apiUrl/api/rides?driverId=$driverId&limit=1&sort=createdAt:desc&startDate=${startDate.toIso8601String()}');
    final headers = _authService.getAuthHeaders();

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        int? rideId;
        
        if (responseData is Map<String, dynamic> && responseData.containsKey('rides')) {
          final List<dynamic> ridesJson = responseData['rides'];
          if (ridesJson.isNotEmpty) {
            final latestRide = ridesJson.first as Map<String, dynamic>;
            rideId = latestRide['id'] ?? latestRide['rideId'];
            rideId = rideId is int ? rideId : int.tryParse(rideId.toString());
          }
        } else if (responseData is List && responseData.isNotEmpty) {
          final latestRide = responseData.first as Map<String, dynamic>;
          rideId = latestRide['id'] ?? latestRide['rideId'];
          rideId = rideId is int ? rideId : int.tryParse(rideId.toString());
        }
        
        // Armazenar no cache
        _cache[cacheKey] = rideId;
        _cacheTimestamps[cacheKey] = DateTime.now();
        
        return rideId;
      } else {
        throw Exception('Falha ao buscar última viagem. Código: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao buscar última viagem: $e');
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getActiveRideForDriver(int driverId) async {
    if (!_authService.isAuthenticated) {
      throw Exception('Usuário não autenticado.');
    }

    if (kDebugMode) {
      debugPrint('🔍 === INÍCIO getActiveRideForDriver ===');
      debugPrint('🔍 RideService: Buscando corrida ativa para motorista $driverId');
    }

    // Buscar corridas com status PENDING, STARTED ou IN_PROGRESS
    final activeStatuses = ['PENDING', 'STARTED', 'IN_PROGRESS'];
    
    for (final status in activeStatuses) {
      final cacheKey = _getCacheKey('/api/rides', {'driverId': driverId, 'status': status, 'limit': 1, 'sort': 'createdAt:desc'});
      if (_isCacheValid(cacheKey)) {
        final cachedRide = _cache[cacheKey] as Map<String, dynamic>?;
        if (cachedRide != null) {
          if (kDebugMode) {
            debugPrint('✅ RideService: Corrida ativa encontrada no cache - Status: $status');
            debugPrint('✅ Cache ride ID: ${cachedRide['id']}');
          }
          return cachedRide;
        }
      }

      // Adicionar filtro de data para corridas recentes (últimos 30 dias)
      final startDate = DateTime.now().subtract(const Duration(days: 30));
      final url = Uri.parse('$apiUrl/api/rides?driverId=$driverId&status=$status&limit=1&sort=createdAt:desc&startDate=${startDate.toIso8601String()}');
      final headers = _authService.getAuthHeaders();

      try {
        if (kDebugMode) {
          debugPrint('🔍 Buscando corridas com status: $status');
          debugPrint('🔍 URL: $url');
        }
        
        final response = await http.get(url, headers: headers);

        if (kDebugMode) {
          debugPrint('🔍 Response Status: ${response.statusCode}');
          debugPrint('🔍 Response Body: ${response.body}');
        }

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          Map<String, dynamic>? activeRide;
          
          if (responseData is Map<String, dynamic> && 
              responseData.containsKey('rides') && 
              (responseData['rides'] as List).isNotEmpty) {
            activeRide = (responseData['rides'] as List).first as Map<String, dynamic>;
            
            if (kDebugMode) {
              debugPrint('✅ RideService: Corrida ativa encontrada - ID: ${activeRide['id']}, Status: ${activeRide['status']}');
            }
            
            // Armazenar no cache
            _cache[cacheKey] = activeRide;
            _cacheTimestamps[cacheKey] = DateTime.now();
            
            if (kDebugMode) {
              debugPrint('🔍 === FIM getActiveRideForDriver (com sucesso) ===');
            }
            return activeRide;
          } else {
            if (kDebugMode) {
              debugPrint('ℹ️ Nenhuma corrida encontrada com status $status');
              if (responseData is Map<String, dynamic>) {
                debugPrint('ℹ️ Response keys: ${responseData.keys.toList()}');
                if (responseData.containsKey('rides')) {
                  debugPrint('ℹ️ Rides array length: ${(responseData['rides'] as List).length}');
                }
              }
            }
          }
        } else if (response.statusCode == 404) {
          if (kDebugMode) {
            debugPrint('ℹ️ Endpoint não encontrado ou sem dados para status $status');
          }
        } else {
          if (kDebugMode) {
            debugPrint('❌ Erro HTTP ${response.statusCode} ao buscar corridas com status $status');
            debugPrint('❌ Response: ${response.body}');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Exceção ao buscar corridas com status $status: $e');
        }
      }
    }

    if (kDebugMode) {
      debugPrint('ℹ️ RideService: Nenhuma corrida ativa encontrada para motorista $driverId');
      debugPrint('🔍 === FIM getActiveRideForDriver (sem corrida ativa) ===');
    }
    
    return null;
  }

  static Future<bool> cancelRide(int rideId) async {
    if (!_authService.isAuthenticated) {
      throw Exception('Usuário não autenticado.');
    }

    if (kDebugMode) {
      debugPrint('🔍 === INÍCIO cancelRide ===');
      debugPrint('🔍 RideService: Cancelando corrida ID: $rideId');
    }

    // Validar rideId
    if (rideId <= 0) {
      throw Exception('ID da corrida inválido: $rideId');
    }

    try {
      // Usar o endpoint correto conforme documentação da API: PATCH /api/rides/{id}/cancel
      final cancelUrl = Uri.parse('$apiUrl/api/rides/$rideId/cancel');
      final headers = _authService.getAuthHeaders();
      
      if (kDebugMode) {
        debugPrint('🔍 URL: $cancelUrl');
        debugPrint('🔍 Headers: $headers');
        debugPrint('🔍 Enviando PATCH cancel request...');
      }
      
      final response = await http.patch(cancelUrl, headers: headers);
      
      if (kDebugMode) {
        debugPrint('🔍 Response Status: ${response.statusCode}');
        debugPrint('🔍 Response Body: ${response.body}');
      }
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        if (kDebugMode) {
          debugPrint('✅ RideService: Corrida $rideId cancelada com sucesso');
        }
        
        _clearRideCache();
        _clearRequestCache();
        clearRidesCache(); // Limpar também o novo cache
        return true;
      } else {
        if (kDebugMode) {
          debugPrint('❌ Erro ao cancelar corrida');
          debugPrint('❌ Status Code: ${response.statusCode}');
          debugPrint('❌ Response Body: ${response.body}');
        }
        
        // Tentar extrair mensagem de erro do servidor
        String errorMessage = 'Falha ao cancelar corrida. Código: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map<String, dynamic> && errorData.containsKey('message')) {
            errorMessage = errorData['message'];
          } else if (errorData is Map<String, dynamic> && errorData.containsKey('error')) {
            errorMessage = errorData['error'];
          }
        } catch (e) {
          // Se não conseguir fazer parse da resposta, usar mensagem padrão
        }
        
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ RideService: Exceção ao cancelar viagem: $e');
        debugPrint('🔍 === FIM cancelRide (com erro) ===');
      }
      
      // Se for um erro de rede/conexão, dar uma mensagem mais amigável
      if (e.toString().contains('SocketException') || 
          e.toString().contains('TimeoutException') ||
          e.toString().contains('HandshakeException')) {
        throw Exception('Erro de conexão. Verifique sua internet e tente novamente.');
      }
      
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

  static Future<Map<String, dynamic>?> getRideById(int rideId) async {
    if (!_authService.isAuthenticated) {
      throw Exception('Usuário não autenticado.');
    }

    if (kDebugMode) {
      debugPrint('🔍 RideService: Buscando corrida por ID: $rideId');
    }

    final url = Uri.parse('$apiUrl/api/rides/$rideId');
    final headers = _authService.getAuthHeaders();

    if (kDebugMode) {
      debugPrint('🔍 URL: $url');
      debugPrint('🔍 Headers: $headers');
    }

    try {
      final response = await http.get(url, headers: headers);

      if (kDebugMode) {
        debugPrint('🔍 Response Status: ${response.statusCode}');
        debugPrint('🔍 Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData is Map<String, dynamic>) {
          if (kDebugMode) {
            debugPrint('✅ Corrida encontrada: ID=${responseData['id']}, Status=${responseData['status']}');
          }
          return responseData;
        } else {
          if (kDebugMode) {
            debugPrint('❌ Formato de resposta inválido');
          }
          return null;
        }
      } else if (response.statusCode == 404) {
        if (kDebugMode) {
          debugPrint('❌ Corrida com ID $rideId não encontrada no servidor (404)');
        }
        return null;
      } else {
        if (kDebugMode) {
          debugPrint('❌ Erro ao buscar corrida: Status ${response.statusCode}');
          debugPrint('❌ Response: ${response.body}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Exceção ao buscar corrida por ID: $e');
      }
      return null;
    }
  }

  /// Método utilitário para extrair rideId de forma segura de qualquer estrutura
  static int? safeExtractRideId(dynamic rideData) {
    if (rideData == null) return null;
    
    // Se já é um int, retornar diretamente
    if (rideData is int) return rideData > 0 ? rideData : null;
    
    // Se é uma string, tentar converter
    if (rideData is String) {
      final parsed = int.tryParse(rideData);
      return parsed != null && parsed > 0 ? parsed : null;
    }
    
    // Se é um Map, tentar extrair de várias chaves possíveis
    if (rideData is Map<String, dynamic>) {
      // Ordem de preferência: id, rideId, ride_id
      for (final key in ['id', 'rideId', 'ride_id']) {
        final value = rideData[key];
        if (value != null) {
          if (value is int) return value > 0 ? value : null;
          if (value is String) {
            final parsed = int.tryParse(value);
            if (parsed != null && parsed > 0) return parsed;
          }
        }
      }
    }
    
    if (kDebugMode) {
      debugPrint('❌ RideService.safeExtractRideId: Não foi possível extrair rideId de: $rideData');
      debugPrint('❌ Tipo: ${rideData.runtimeType}');
    }
    
    return null;
  }

  /// Versão melhorada do startRide que aceita diferentes tipos de entrada
  static Future<bool> startRideFlexible(dynamic rideData) async {
    final rideId = safeExtractRideId(rideData);
    
    if (rideId == null) {
      throw Exception('ID da corrida inválido ou não encontrado: $rideData');
    }
    
    return startRide(rideId);
  }

  /// Versão melhorada do cancelRide que aceita diferentes tipos de entrada
  static Future<bool> cancelRideFlexible(dynamic rideData) async {
    final rideId = safeExtractRideId(rideData);
    
    if (rideId == null) {
      throw Exception('ID da corrida inválido ou não encontrado: $rideData');
    }
    
    return cancelRide(rideId);
  }

  /// Versão melhorada do updateRideStatus que aceita diferentes tipos de entrada
  static Future<bool> updateRideStatusFlexible(dynamic rideData, String status) async {
    final rideId = safeExtractRideId(rideData);
    
    if (rideId == null) {
      throw Exception('ID da corrida inválido ou não encontrado: $rideData');
    }
    
    return updateRideStatus(rideId, status);
  }

  /// Atualiza o status de uma corrida
  static Future<bool> updateRideStatus(int rideId, String status) async {
    if (kDebugMode) {
      debugPrint('🔍 === INÍCIO updateRideStatus ===');
      debugPrint('🔍 Versão do método: NOVA (com simulação local)');
      debugPrint('🔍 RideId recebido: $rideId');
      debugPrint('🔍 Status recebido: $status');
    }

    if (!_authService.isAuthenticated) {
      throw Exception('Usuário não autenticado.');
    }

    // Validações de entrada
    if (rideId <= 0) {
      throw Exception('ID da corrida inválido: $rideId');
    }

    // Validar status permitidos
    final allowedStatuses = ['PENDING', 'STARTED', 'IN_PROGRESS', 'COMPLETED', 'CANCELED'];
    final upperStatus = status.toUpperCase();
    if (!allowedStatuses.contains(upperStatus)) {
      throw Exception('Status inválido: $status. Permitidos: ${allowedStatuses.join(', ')}');
    }

    if (kDebugMode) {
      debugPrint('--- RideService: Atualizando status da corrida ---');
      debugPrint('Ride ID: $rideId');
      debugPrint('Status original: $status');
      debugPrint('Status normalizado: $upperStatus');
      debugPrint('🔍 Verificando tipo de status...');
    }

    try {
      // Para cancelamento, usar o endpoint DELETE que já existe
      if (upperStatus == 'CANCELED') {
        if (kDebugMode) {
                      debugPrint('🔍 Status é CANCELED - usando DELETE');
        }
        final success = await cancelRide(rideId);
        if (success) {
          if (kDebugMode) {
            debugPrint('✅ Corrida cancelada com sucesso usando DELETE!');
          }
          return true;
        } else {
          throw Exception('Falha ao cancelar corrida via DELETE');
        }
      }
      
      // Para outros status (STARTED, IN_PROGRESS, COMPLETED), usar PATCH no backend
      if (upperStatus == 'STARTED' || upperStatus == 'IN_PROGRESS' || upperStatus == 'COMPLETED') {
        if (kDebugMode) {
          debugPrint('🔍 Status é $upperStatus - enviando PATCH para backend');
        }
        
        final url = Uri.parse('$apiUrl/api/rides/$rideId/status');
        final headers = _authService.getAuthHeaders();
        
        // Garantir que o Content-Type está correto
        if (!headers.containsKey('Content-Type')) {
          headers['Content-Type'] = 'application/json';
        }
        
        final body = jsonEncode({'status': upperStatus});
        
        if (kDebugMode) {
          debugPrint('🔍 URL: $url');
          debugPrint('🔍 Headers: $headers');
          debugPrint('🔍 Body: $body');
        }
        
        final response = await http.patch(url, headers: headers, body: body);
        
        if (kDebugMode) {
          debugPrint('🔍 Response Status: ${response.statusCode}');
          debugPrint('🔍 Response Body: ${response.body}');
        }
        
        if (response.statusCode == 200 || response.statusCode == 204) {
          if (kDebugMode) {
            debugPrint('✅ Status da corrida atualizado com sucesso no backend!');
          }
          
          // Limpar cache para forçar atualização
          _clearRideCache();
          return true;
        } else {
          if (kDebugMode) {
            debugPrint('❌ Erro ao atualizar status no backend');
            debugPrint('❌ Status Code: ${response.statusCode}');
            debugPrint('❌ Response Body: ${response.body}');
          }
          
          // Se falhar no backend, vamos tentar uma abordagem alternativa
          // Usar PUT na rota principal da corrida
          final putUrl = Uri.parse('$apiUrl/api/rides/$rideId');
          final putBody = jsonEncode({'status': upperStatus});
          
          if (kDebugMode) {
            debugPrint('🔄 Tentando PUT alternativo: $putUrl');
          }
          
          final putResponse = await http.put(putUrl, headers: headers, body: putBody);
          
          if (putResponse.statusCode == 200 || putResponse.statusCode == 204) {
            if (kDebugMode) {
              debugPrint('✅ Status atualizado com PUT alternativo!');
            }
            _clearRideCache();
            return true;
          } else {
            throw Exception('Falha ao atualizar status da corrida. PATCH: ${response.statusCode}, PUT: ${putResponse.statusCode}');
          }
        }
      }
      
      // Status não implementado
      if (kDebugMode) {
        debugPrint('❌ Status $upperStatus não implementado');
      }
      throw Exception('Status $upperStatus não implementado no backend atual');
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Exceção ao atualizar status da corrida: $e');
        debugPrint('🔍 === FIM updateRideStatus (com erro) ===');
      }
      rethrow;
    }
  }

  /// Inicia uma corrida usando a rota específica /api/rides/{id}/start
  static Future<bool> startRide(int rideId) async {
    if (kDebugMode) {
      debugPrint('🚀 === INÍCIO startRide ===');
      debugPrint('🚀 RideId: $rideId');
    }

    if (!_authService.isAuthenticated) {
      throw Exception('Usuário não autenticado.');
    }

    if (rideId <= 0) {
      throw Exception('ID da corrida inválido: $rideId');
    }

    try {
      final url = Uri.parse('$apiUrl/api/rides/$rideId/start');
      final headers = _authService.getAuthHeaders();
      
      if (!headers.containsKey('Content-Type')) {
        headers['Content-Type'] = 'application/json';
      }
      
      if (kDebugMode) {
        debugPrint('🚀 URL: $url');
        debugPrint('🚀 Headers: $headers');
        debugPrint('🚀 Enviando PATCH request...');
      }
      
      final response = await http.patch(url, headers: headers);
      
      if (kDebugMode) {
        debugPrint('🚀 Response Status: ${response.statusCode}');
        debugPrint('🚀 Response Body: ${response.body}');
      }
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (kDebugMode) {
          debugPrint('✅ Corrida iniciada com sucesso!');
          debugPrint('✅ Status: ${responseData['status']}');
          debugPrint('✅ Message: ${responseData['message']}');
          debugPrint('✅ StartedAt: ${responseData['startedAt']}');
        }
        
        // Limpar cache para forçar atualização
        _clearRideCache();
        return true;
      } else {
        if (kDebugMode) {
          debugPrint('❌ Erro ao iniciar corrida');
          debugPrint('❌ Status Code: ${response.statusCode}');
          debugPrint('❌ Response Body: ${response.body}');
        }
        
        // Tentar extrair mensagem de erro do servidor
        String errorMessage = 'Falha ao iniciar corrida. Código: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map<String, dynamic> && errorData.containsKey('message')) {
            errorMessage = errorData['message'];
          }
        } catch (e) {
          // Se não conseguir fazer parse da resposta, usar mensagem padrão
        }
        
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Exceção ao iniciar corrida: $e');
        debugPrint('🚀 === FIM startRide (com erro) ===');
      }
      rethrow;
    }
  }

  static Future<List<Ride>> getAllRides({
    int limit = 100,
    String sortBy = 'createdAt:desc',
  }) async {
    if (!_authService.isAuthenticated) {
      throw Exception('Usuário não autenticado. Faça o login para ver as corridas.');
    }

    // Construir parâmetros da URL (sem filtro de data para histórico completo)
    final params = <String, String>{
      'limit': limit.toString(),
      'sort': sortBy,
    };

    final cacheKey = _getCacheKey('/api/rides/all', params);
    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey] as List<Ride>;
    }

    // Construir URL com parâmetros
    final uri = Uri.parse('$apiUrl/api/rides').replace(queryParameters: params);
    final headers = _authService.getAuthHeaders();

    if (kDebugMode) {
      debugPrint('🔍 RideService.getAllRides: Buscando todas as corridas');
      debugPrint('🔍 URL: $uri');
    }

    try {
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('rides') &&
            responseData['rides'] is List) {
          final List<dynamic> ridesJson = responseData['rides'];
          final rides = ridesJson.map((json) => Ride.fromJson(json)).toList();
          
          if (kDebugMode) {
            debugPrint('✅ Total de corridas (incluindo históricas): ${rides.length}');
          }
          
          // Armazenar no cache
          _cache[cacheKey] = rides;
          _cacheTimestamps[cacheKey] = DateTime.now();
          
          return rides;
        } else {
          return [];
        }
      } else {
        throw Exception('Falha ao carregar corridas. Código: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao buscar todas as corridas: $e');
      }
      rethrow;
    }
  }

  /// Limpa todo o cache do RideService
  static void clearAllCache() {
    _cache.clear();
    _cacheTimestamps.clear();
    if (kDebugMode) {
      debugPrint('🧹 RideService: Cache completamente limpo');
    }
  }

  /// Limpa apenas o cache de rides
  static void clearRidesCache() {
    final keysToRemove = _cache.keys.where((key) => key.contains('/api/rides')).toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
    if (kDebugMode) {
      debugPrint('🧹 RideService: Cache de rides limpo');
    }
  }

  /// Método utilitário para validar e extrair o rideId de forma consistente (compatibilidade)
  static int? extractRideId(dynamic data) {
    return safeExtractRideId(data);
  }

  /// Método utilitário para validar se o rideId está presente e é válido
  static bool isValidRideId(dynamic rideId) {
    final extracted = safeExtractRideId(rideId);
    return extracted != null && extracted > 0;
  }

  /// Método de debug para diagnosticar estrutura de dados de corrida
  static void debugRideDataStructure(dynamic rideData, {String? context}) {
    if (!kDebugMode) return;
    
    debugPrint('🔍 === DEBUG RIDE DATA STRUCTURE ===');
    if (context != null) {
      debugPrint('🔍 Contexto: $context');
    }
    debugPrint('🔍 Tipo: ${rideData.runtimeType}');
    debugPrint('🔍 Valor: $rideData');
    
    if (rideData is Map<String, dynamic>) {
      debugPrint('🔍 Chaves disponíveis: ${rideData.keys.toList()}');
      debugPrint('🔍 id: ${rideData['id']} (${rideData['id'].runtimeType})');
      debugPrint('🔍 rideId: ${rideData['rideId']} (${rideData['rideId']?.runtimeType})');
      debugPrint('🔍 driverId: ${rideData['driverId']} (${rideData['driverId']?.runtimeType})');
      debugPrint('🔍 status: ${rideData['status']} (${rideData['status']?.runtimeType})');
    }
    
    final extractedId = safeExtractRideId(rideData);
    debugPrint('🔍 ID extraído: $extractedId');
    debugPrint('🔍 ID válido: ${isValidRideId(rideData)}');
    debugPrint('🔍 === FIM DEBUG ===');
  }

  /// Finaliza uma corrida usando a rota específica /api/rides/{id}/complete
  static Future<bool> completeRide(int rideId) async {
    if (kDebugMode) {
      debugPrint('🏁 === INÍCIO completeRide ===');
      debugPrint('🏁 RideId: $rideId');
    }

    if (!_authService.isAuthenticated) {
      throw Exception('Usuário não autenticado.');
    }

    if (rideId <= 0) {
      throw Exception('ID da corrida inválido: $rideId');
    }

    try {
      final url = Uri.parse('$apiUrl/api/rides/$rideId/status');
      final headers = _authService.getAuthHeaders();
      
      if (!headers.containsKey('Content-Type')) {
        headers['Content-Type'] = 'application/json';
      }
      
      final body = jsonEncode({'status': 'completed'});
      
      if (kDebugMode) {
        debugPrint('🏁 URL: $url');
        debugPrint('🏁 Headers: $headers');                    
        debugPrint('🏁 Body: $body');
        debugPrint('🏁 Enviando PATCH request...');
      }
      
      final response = await http.patch(url, headers: headers, body: body);
      
      if (kDebugMode) {
        debugPrint('🏁 Response Status: ${response.statusCode}');
        debugPrint('🏁 Response Body: ${response.body}');
      }
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (kDebugMode) {
          debugPrint('✅ Corrida finalizada com sucesso!');
          debugPrint('✅ Status: ${responseData['status']}');
          debugPrint('✅ Message: ${responseData['message']}');
          debugPrint('✅ CompletedAt: ${responseData['completedAt']}');
        }
        
        // Limpar cache para forçar atualização
        _clearRideCache();
        return true;
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ Endpoint /complete não disponível, tentando método alternativo...');
        }
        
        // Se o endpoint específico não existir, usar método genérico
        return await updateRideStatus(rideId, 'COMPLETED');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Erro no endpoint /complete: $e');
        debugPrint('🔄 Tentando método alternativo...');
      }
      
      try {
        // Fallback para método genérico
        return await updateRideStatus(rideId, 'COMPLETED');
      } catch (fallbackError) {
        if (kDebugMode) {
          debugPrint('❌ Ambos os métodos falharam');
          debugPrint('❌ Erro específico: $e');
          debugPrint('❌ Erro genérico: $fallbackError');
          debugPrint('🏁 === FIM completeRide (com erro) ===');
        }
        rethrow;
      }
    }
  }

  /// Versão flexível para finalizar corridas que aceita qualquer tipo de dados
  static Future<bool> completeRideFlexible(dynamic rideData) async {
    final rideId = safeExtractRideId(rideData);
    if (rideId == null) {
      throw Exception('Não foi possível extrair ID da corrida dos dados fornecidos');
    }
    return await completeRide(rideId);
  }
} 