import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/ride_history.dart';
import '../config/app_config.dart';
import 'auth_service.dart';

class RideHistoryService {
  static final RideHistoryService _instance = RideHistoryService._internal();
  factory RideHistoryService() => _instance;
  RideHistoryService._internal();

  final AuthService _authService = AuthService();

  Future<RideHistoryResponse> getRideHistory({
    int? userId,
    int page = 1,
    int size = 10,
  }) async {
    final token = _authService.token;
    if (token == null) {
      throw Exception('Usuário não autenticado');
    }

    final currentUser = _authService.currentUser;
    final targetUserId = userId ?? currentUser?.userId;
    
    if (targetUserId == null) {
      throw Exception('ID do usuário não disponível');
    }

    final url = Uri.parse('${AppConfig.baseUrl}/api/rides/history')
        .replace(queryParameters: {
      'userId': targetUserId.toString(),
      'page': page.toString(),
      'size': size.toString(),
    });

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return RideHistoryResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Token de autenticação inválido');
      } else if (response.statusCode == 404) {
        throw Exception('Histórico de viagens não encontrado');
      } else if (response.statusCode >= 500) {
        throw Exception('Erro interno do servidor');
      } else {
        throw Exception('Erro ao buscar histórico de viagens: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Tempo limite esgotado. Verifique sua conexão com a internet.');
    } on SocketException {
      throw Exception('Sem conexão com a internet. Verifique sua rede.');
    } on FormatException {
      throw Exception('Resposta inválida do servidor.');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Erro inesperado ao buscar histórico: ${e.toString()}');
    }
  }

  Future<RideHistory> getRideDetails(int rideId) async {
    final token = _authService.token;
    if (token == null) {
      throw Exception('Usuário não autenticado');
    }

    final url = Uri.parse('${AppConfig.baseUrl}/api/rides/$rideId');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return RideHistory.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Token de autenticação inválido');
      } else if (response.statusCode == 404) {
        throw Exception('Viagem não encontrada');
      } else if (response.statusCode >= 500) {
        throw Exception('Erro interno do servidor');
      } else {
        throw Exception('Erro ao buscar detalhes da viagem: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Tempo limite esgotado. Verifique sua conexão com a internet.');
    } on SocketException {
      throw Exception('Sem conexão com a internet. Verifique sua rede.');
    } on FormatException {
      throw Exception('Resposta inválida do servidor.');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Erro inesperado ao buscar detalhes da viagem: ${e.toString()}');
    }
  }
} 