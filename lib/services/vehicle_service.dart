import 'dart:convert';

import 'package:flutter/rendering.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/models/vehicle.dart';
import 'package:mobile_app/services/auth_service.dart';

class VehicleService {
  static final String apiUrl = dotenv.env['API_URL'] ?? 'http://10.0.2.2:4040/';
  static final AuthService _authService = AuthService();  static Future<bool> registerVehicle(Vehicle vehicle) async {
    try {
      if (!_authService.isAuthenticated) {
        debugPrint('User not authenticated');
        throw Exception('Usuário não autenticado');
      }

      // Get the current user's driver ID
      final currentUser = _authService.currentUser;
      if (currentUser?.driver?.id == null) {
        debugPrint('Driver ID not found for current user');
        throw Exception('Informações do motorista não encontradas');
      }

      // Update vehicle with the correct driver ID
      final vehicleData = vehicle.toJson();
      vehicleData['driverId'] = currentUser!.driver!.id;
      
      // Remove null values that might cause issues
      vehicleData.removeWhere((key, value) => value == null);

      debugPrint('Registering vehicle at: $apiUrl/api/vehicles/');
      debugPrint('Vehicle data: $vehicleData');
      
      final response = await http.post(
        Uri.parse('$apiUrl/api/vehicles/'),
        headers: _authService.getAuthHeaders(),
        body: jsonEncode(vehicleData),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('Vehicle registered successfully');
        return true;
      } else if (response.statusCode == 401) {
        debugPrint('Authentication failed');
        throw Exception('Sessão expirada. Faça login novamente.');
      } else {
        debugPrint(
          'Failed to register vehicle: ${response.statusCode} ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error registering vehicle: $e');
      rethrow;
    }
  }  static Future<List<Vehicle>> getVehiclesByDriverId() async {
    try {
      if (!_authService.isAuthenticated) {
        debugPrint('User not authenticated');
        throw Exception('Usuário não autenticado');
      }

      // Get the current user's driver ID
      final currentUser = _authService.currentUser;
      if (currentUser?.driver?.id == null) {
        debugPrint('Driver ID not found for current user');
        throw Exception('Informações do motorista não encontradas');
      }      final driverId = currentUser!.driver!.id;
      debugPrint('Getting vehicles for driver ID: $driverId');

      final url = '$apiUrl/api/vehicles/driver/$driverId';
      debugPrint('Making request to: $url');
      debugPrint('Headers: ${_authService.getAuthHeaders()}');

      final response = await http.get(
        Uri.parse(url),
        headers: _authService.getAuthHeaders(),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        debugPrint('Response data structure: $responseData');
          // Check if the response has a vehicles array
        if (responseData.containsKey('vehicles')) {
          final List<dynamic> vehiclesJson = responseData['vehicles'];
          debugPrint('Found ${vehiclesJson.length} vehicles in response');
          
          List<Vehicle> vehicles = [];
          for (int i = 0; i < vehiclesJson.length; i++) {
            try {
              final vehicleJson = vehiclesJson[i];
              debugPrint('Parsing vehicle $i: $vehicleJson');
              final vehicle = Vehicle.fromJson(vehicleJson);
              vehicles.add(vehicle);
              debugPrint('Successfully parsed vehicle: ${vehicle.brand} ${vehicle.model}');
            } catch (e) {
              debugPrint('Error parsing vehicle $i: $e');
            }
          }
          
          debugPrint('Successfully parsed ${vehicles.length} vehicles');
          return vehicles;
        } else {
          // Fallback: try to treat the response as a direct array
          final List<dynamic> vehiclesJson = jsonDecode(response.body);
          debugPrint('Treating response as direct array with ${vehiclesJson.length} vehicles');
          return vehiclesJson.map((json) => Vehicle.fromJson(json)).toList();
        }
      } else if (response.statusCode == 401) {
        debugPrint('Authentication failed');
        throw Exception('Sessão expirada. Faça login novamente.');
      } else {
        debugPrint('Failed to get vehicles: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error getting vehicles: $e');
      if (e.toString().contains('Usuário não autenticado') || 
          e.toString().contains('Sessão expirada') ||
          e.toString().contains('Informações do motorista não encontradas')) {
        rethrow;
      }
      return [];
    }
  }
  static Future<bool> updateVehicle(Vehicle vehicle) async {
    try {
      if (!_authService.isAuthenticated) {
        debugPrint('User not authenticated');
        throw Exception('Usuário não autenticado');
      }

      final response = await http.put(
        Uri.parse('$apiUrl/api/vehicles/${vehicle.id}'),
        headers: _authService.getAuthHeaders(),
        body: jsonEncode(vehicle.toJson()),
      );

      if (response.statusCode == 200) {
        debugPrint('Vehicle updated successfully');
        return true;
      } else if (response.statusCode == 401) {
        debugPrint('Authentication failed');
        throw Exception('Sessão expirada. Faça login novamente.');
      } else {
        debugPrint(
          'Failed to update vehicle: ${response.statusCode} ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error updating vehicle: $e');
      rethrow;
    }
  }
  static Future<bool> deleteVehicle(int vehicleId) async {
    try {
      if (!_authService.isAuthenticated) {
        debugPrint('User not authenticated');
        throw Exception('Usuário não autenticado');
      }

      final response = await http.delete(
        Uri.parse('$apiUrl/api/vehicles/$vehicleId'),
        headers: _authService.getAuthHeaders(),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('Vehicle deleted successfully');
        return true;
      } else if (response.statusCode == 401) {
        debugPrint('Authentication failed');
        throw Exception('Sessão expirada. Faça login novamente.');
      } else {
        debugPrint(
          'Failed to delete vehicle: ${response.statusCode} ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error deleting vehicle: $e');
      rethrow;
    }
  }
}
