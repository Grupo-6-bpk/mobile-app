import 'package:flutter/material.dart';

class Ride {
  final int id;
  final String startLocation;
  final String endLocation;
  final DateTime departureTime;
  final double? pricePerMember;
  final double? totalCost;
  final double? fuelPrice;
  final int totalSeats;
  final int availableSeats;
  final String status;
  final Driver driver;
  final Vehicle vehicle;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Ride({
    required this.id,
    required this.startLocation,
    required this.endLocation,
    required this.departureTime,
    this.pricePerMember,
    this.totalCost,
    this.fuelPrice,
    required this.totalSeats,
    required this.availableSeats,
    required this.status,
    required this.driver,
    required this.vehicle,
    this.createdAt,
    this.updatedAt,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    final totalSeats = json['totalSeats'] ?? 0;
    final availableSeats = json['availableSeats'] ?? 0;
    final status = json['status'] ?? 'PENDING';

    debugPrint('Ride.fromJson: totalSeats do JSON: $totalSeats');
    debugPrint('Ride.fromJson: availableSeats do JSON: $availableSeats');
    debugPrint('Ride.fromJson: status do JSON: $status');

    return Ride(
      id: json['id'],
      startLocation: json['startLocation'],
      endLocation: json['endLocation'],
      departureTime: DateTime.parse(json['departureTime']),
      pricePerMember: (json['pricePerMember'] as num?)?.toDouble(),
      totalCost: (json['totalCost'] as num?)?.toDouble(),
      fuelPrice: (json['fuelPrice'] as num?)?.toDouble(),
      totalSeats: totalSeats,
      availableSeats: availableSeats,
      status: status,
      driver: Driver.fromJson(json['driver']),
      vehicle: Vehicle.fromJson(json['vehicle']),
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }
}

class Driver {
  final int id;
  final int userId;
  final String? name; // Name is often missing, so it is nullable

  Driver({required this.id, required this.userId, this.name});

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(id: json['id'], userId: json['userId'], name: json['name']);
  }
}

class Vehicle {
  final int id;
  final String model;
  final String brand;
  final String plate;

  Vehicle({
    required this.id,
    required this.model,
    required this.brand,
    required this.plate,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      model: json['model'],
      brand: json['brand'],
      plate: json['plate'],
    );
  }
}
