class Vehicle {
  int? id;
  String model;
  String brand;
  int year;
  String color;
  String renavam;
  String plate;
  double fuelConsumption;
  String? carImageUrl;
  int driverId;
  DateTime? createdAt;
  DateTime? updatedAt;

  Vehicle({
    this.id,
    required this.model,
    required this.brand,
    required this.year,
    required this.color,
    required this.renavam,
    required this.plate,
    required this.fuelConsumption,
    this.carImageUrl,
    required this.driverId,
    this.createdAt,
    this.updatedAt,
  });  Vehicle.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        model = json['model'] ?? '',
        brand = json['brand'] ?? '',
        year = json['year'] ?? 0,
        color = json['color'] ?? '',
        renavam = json['renavam'] ?? '',
        plate = json['plate'] ?? '',
        fuelConsumption = (json['fuelConsumption'] ?? 0).toDouble(),
        carImageUrl = json['carImageUrl'],
        driverId = json['driverId'] ?? 0,
        createdAt = json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : null,
        updatedAt = json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : null;
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'model': model,
      'brand': brand,
      'year': year,
      'color': color,
      'renavam': renavam,
      'plate': plate,
      'fuelConsumption': fuelConsumption,
      'carImageUrl': carImageUrl,
      'driverId': driverId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
