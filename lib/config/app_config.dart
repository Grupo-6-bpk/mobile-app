import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get baseUrl => dotenv.env['API_URL'] ?? 'http://10.0.2.2:4040';
  static String get apiBaseUrl => '$baseUrl/api';
  static String get webSocketUrl => baseUrl.replaceFirst('http', 'ws');
  
  static const String loginEndpoint = 'login';
  static const String chatsEndpoint = 'api/chats';
  static const String usersSearchEndpoint = 'api/users/search';
  
  static const int messagePageSize = 20;
  static const int maxRetryAttempts = 3;
  static const int reconnectionDelay = 1000; // ms
  
  static const String tokenKey = 'jwt_token';
  static const String userKey = 'current_user';
  static const String databaseName = 'chat_database.db';
  
  static const int minPasswordLength = 6;
  static const int maxMessageLength = 1000;
  
  static List<String> get testUrls => [baseUrl];
}