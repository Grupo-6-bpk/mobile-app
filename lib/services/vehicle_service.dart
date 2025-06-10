import 'dart:convert';

import 'package:flutter/rendering.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/models/vehicle.dart';

class VehicleService {
  static final String apiUrl = dotenv.env['API_URL'] ?? 'http://10.0.2.2:4040/';

  static Future<bool> registerVehicle(Vehicle vehicle) async {
    try {
      debugPrint('Registering vehicle at: ${apiUrl}/api/vehicles/');
      final response = await http.post(
        Uri.parse('${apiUrl}/api/vehicles/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(vehicle.toJson()),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('Vehicle registered successfully');
        return true;
      } else {
        debugPrint(
          'Failed to register vehicle: ${response.statusCode} ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error registering vehicle: $e');
      return false;
    }
  }

  static Future<List<Vehicle>> getVehiclesByDriverId(int driverId) async {
    try {
      final response = await http.get(
        Uri.parse('${apiUrl}/api/vehicles/driver/$driverId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> vehiclesJson = jsonDecode(response.body);
        return vehiclesJson.map((json) => Vehicle.fromJson(json)).toList();
      } else {
        debugPrint('Failed to get vehicles: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error getting vehicles: $e');
      return [];
    }
  }

  static Future<bool> updateVehicle(Vehicle vehicle) async {
    try {
      final response = await http.put(
        Uri.parse('${apiUrl}/api/vehicles/${vehicle.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(vehicle.toJson()),
      );

      if (response.statusCode == 200) {
        debugPrint('Vehicle updated successfully');
        return true;
      } else {
        debugPrint(
          'Failed to update vehicle: ${response.statusCode} ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error updating vehicle: $e');
      return false;
    }
  }

  static Future<bool> deleteVehicle(int vehicleId) async {
    try {
      final response = await http.delete(
        Uri.parse('${apiUrl}/api/vehicles/$vehicleId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('Vehicle deleted successfully');
        return true;
      } else {
        debugPrint(
          'Failed to delete vehicle: ${response.statusCode} ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error deleting vehicle: $e');
      return false;
    }
  }
}
