class Ride {
  final int id;
  final String startLocation;
  final String endLocation;
  final DateTime departureTime;
  final double? pricePerMember;
  final int availableSeats;
  final Driver driver;
  final Vehicle vehicle;

  Ride({
    required this.id,
    required this.startLocation,
    required this.endLocation,
    required this.departureTime,
    this.pricePerMember,
    required this.availableSeats,
    required this.driver,
    required this.vehicle,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['id'],
      startLocation: json['startLocation'],
      endLocation: json['endLocation'],
      departureTime: DateTime.parse(json['departureTime']),
      pricePerMember: (json['pricePerMember'] as num?)?.toDouble(),
      availableSeats: json['availableSeats'],
      driver: Driver.fromJson(json['driver']),
      vehicle: Vehicle.fromJson(json['vehicle']),
    );
  }
}

class Driver {
  final int id;
  final int userId;
  final String? name; // Name is often missing, so it is nullable

  Driver({required this.id, required this.userId, this.name});

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'],
      userId: json['userId'],
      name: json['name'],
    );
  }
}

class Vehicle {
  final int id;
  final String model;
  final String brand;
  final String plate;

  Vehicle(
      {required this.id,
      required this.model,
      required this.brand,
      required this.plate});

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      model: json['model'],
      brand: json['brand'],
      plate: json['plate'],
    );
  }
} 