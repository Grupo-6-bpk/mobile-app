import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class SettingsService {
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
}
