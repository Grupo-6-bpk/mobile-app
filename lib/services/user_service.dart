import 'dart:convert';

import 'package:flutter/rendering.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart';
import 'package:mobile_app/models/user.dart';

class UserService {
  static final String apiUrl = dotenv.env['API_URL'] ?? 'http://10.0.2.2:4040/';

  static Future<bool> registerUser(User user) async {
    try {
      debugPrint(apiUrl);
      final response = await post(
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
}
