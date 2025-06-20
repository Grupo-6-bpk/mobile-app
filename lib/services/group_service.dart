import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/config/app_config.dart';

class Group {
  final int id;
  final String name;
  final String? description;
  final int driverId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Group({
    required this.id,
    required this.name,
    this.description,
    required this.driverId,
    this.createdAt,
    this.updatedAt,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      driverId: json['driverId'] ?? 0,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'driverId': driverId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class GroupService {
  static final String apiUrl = AppConfig.baseUrl;
  static final AuthService _authService = AuthService();

  static Future<List<Group>> getGroupsByUser(int userId, String role) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('Usuário não autenticado');
      }

      final response = await http.get(
        Uri.parse('$apiUrl/api/groups/by-user?userId=$userId&role=$role'),
        headers: _authService.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> groupsJson = jsonDecode(response.body);
        return groupsJson.map((json) => Group.fromJson(json)).toList();
      } else {
        throw Exception('Erro ao buscar grupos: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro ao buscar grupos: $e');
    }
  }
} 