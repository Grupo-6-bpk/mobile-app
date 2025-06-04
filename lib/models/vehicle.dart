class Vehicle {
  int? id;
  String model;
  String brand;
  int year;
  String phone;
  String street;
  int number;
  String renavam;
  String plate;
  double fuelConsumption;
  int driverId;
  DateTime? createdAt;
  DateTime? updatedAt;

  Vehicle({
    this.id,
    required this.model,
    required this.brand,
    required this.year,
    required this.phone,
    required this.street,
    required this.number,
    required this.renavam,
    required this.plate,
    required this.fuelConsumption,
    required this.driverId,
    this.createdAt,
    this.updatedAt,
  });

  Vehicle.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        model = json['model'],
        brand = json['brand'],
        year = json['year'],
        phone = json['phone'],
        street = json['street'],
        number = json['number'],
        renavam = json['renavam'],
        plate = json['plate'],
        fuelConsumption = json['fuelConsumption'].toDouble(),
        driverId = json['driverId'],
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
      'phone': phone,
      'street': street,
      'number': number,
      'renavam': renavam,
      'plate': plate,
      'fuelConsumption': fuelConsumption,
      'driverId': driverId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
