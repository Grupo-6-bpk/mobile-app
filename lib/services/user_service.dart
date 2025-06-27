import 'dart:convert';

import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/config/app_config.dart';
import 'package:mobile_app/models/user.dart';
import 'package:mobile_app/services/auth_service.dart';

class UserService {
  static final String apiUrl = AppConfig.baseUrl;
  static final AuthService _authService = AuthService();

  static Future<bool> registerUser(User user) async {
    try {
      debugPrint(apiUrl);
      final response = await http.post(
        Uri.parse("$apiUrl/register/"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(user.toJson()),
      );

      if (response.statusCode == 201) {
        debugPrint('User registered successfully');
        return true;
      } else {
        debugPrint(
          'Failed to register user: ${response.statusCode} ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error registering driver: $e');
      return false;
    }
  }

  static Future<User> getUserById(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/api/users/$userId'),
        headers: _authService.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Erro ao buscar usuário: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na requisição do usuário: $e');
    }
  }
}
