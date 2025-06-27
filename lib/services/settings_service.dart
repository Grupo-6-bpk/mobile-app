import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mobile_app/config/app_config.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class SettingsService {
  static final AuthService _authService = AuthService();
  Future<String> _getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/settings.json';
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    final path = await _getFilePath();
    final file = File(path);
    await file.writeAsString(jsonEncode(settings));
  }

  Future<Map<String, dynamic>?> readSettings() async {
    try {
      final path = await _getFilePath();
      final file = File(path);

      if (!await file.exists()) return null;

      final contents = await file.readAsString();
      return jsonDecode(contents);
    } catch (e) {
      debugPrint('Erro ao ler o arquivo: $e');
      return null;
    }
  }

  Future<bool> editEmail(String email, int userId) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}users/$userId/email');

    try {
      debugPrint("Url ${url.toString()}");
      final response = await http.patch(
        url,
        headers: _authService.getAuthHeaders(),
        body: jsonEncode({'email': email}),
      );
      debugPrint('${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('Erro ao editar o email do usuário: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Erro ao editar o email do usuário: $e');
      return false;
    }
  }
}
