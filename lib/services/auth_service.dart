import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../config/app_config.dart';

class AuthService {
  static Database? _database;
  String? _token;
  User? _currentUser;

  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  String? get token => _token;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _token != null;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), AppConfig.databaseName);
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE auth_tokens (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            token TEXT NOT NULL,
            user_data TEXT NOT NULL,
            created_at TEXT NOT NULL,
            expires_at TEXT
          )
        ''');
      },
    );
  }

  Map<String, dynamic>? _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      String payload = parts[1];
      switch (payload.length % 4) {
        case 0:
          break;
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
        default:
          throw Exception('Formato de base64 inválido');
      }
      final decodedBytes = base64.decode(payload);
      final decodedJson = utf8.decode(decodedBytes);
      return jsonDecode(decodedJson);
    } catch (e) {
      return null;
    }
  }

  Future<bool> login(String email, String password) async {
    final url = '${AppConfig.baseUrl}/${AppConfig.loginEndpoint}';
    try {
      debugPrint(url);
      final requestBody = jsonEncode({'email': email, 'password': password});
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: requestBody,
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          if (data['token'] != null) {
            _token = data['token'];
            final jwtPayload = _decodeJwtPayload(_token!);
            if (jwtPayload != null && jwtPayload['id'] != null) {
              _currentUser = User(
                userId: jwtPayload['id'] ?? 0,
                name: email.split('@')[0],
                email: jwtPayload['email'] ?? email,
                phone: '',
                avatarUrl: null,
              );
            } else {
              _currentUser = User(
                userId: 0,
                name: email.split('@')[0],
                email: email,
                phone: '',
                avatarUrl: null,
              );
            }
            await _saveTokenToStorage(_token!);
            await _saveUserToStorage(_currentUser!);
            return true;
          } else {
            return false;
          }
        } catch (jsonError) {
          return false;
        }
      } else if (response.statusCode == 401) {
        return false;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<void> _saveTokenToStorage(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.tokenKey, token);
    final db = await database;
    await db.insert('auth_tokens', {
      'token': token,
      'user_data': _currentUser?.toJson().toString() ?? '',
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _saveUserToStorage(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.userKey, jsonEncode(user.toJson()));
  }

  Future<void> loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(AppConfig.tokenKey);
      final userData = prefs.getString(AppConfig.userKey);
      if (userData != null) {
        _currentUser = User.fromJson(jsonDecode(userData));
      }
    } catch (e) {
      debugPrint('Erro ao carregar dados de autenticação: $e');
    }
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConfig.tokenKey);
      await prefs.remove(AppConfig.userKey);
      final db = await database;
      await db.delete('auth_tokens');
    } catch (e) {
      debugPrint('Erro ao limpar dados de autenticação: $e');
    }
  }

  Map<String, String> getAuthHeaders() {
    if (_token == null) return {};
    return {
      'Authorization': 'Bearer $_token',
      'Content-Type': 'application/json',
    };
  }

  bool requiresLogin() {
    return !isAuthenticated;
  }

  Future<http.Response> authenticatedRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final headers = getAuthHeaders();
    final uri = Uri.parse('${AppConfig.baseUrl}$endpoint');
    switch (method.toUpperCase()) {
      case 'GET':
        return await http.get(uri, headers: headers);
      case 'POST':
        return await http.post(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'PUT':
        return await http.put(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'DELETE':
        return await http.delete(uri, headers: headers);
      default:
        throw ArgumentError('Método HTTP não suportado: $method');
    }
  }
}
