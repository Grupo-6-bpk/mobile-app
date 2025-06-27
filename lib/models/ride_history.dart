class RideHistory {
  final int id;
  final String? type;
  final String? startLocation;
  final String? endLocation;
  final double distance;
  final DateTime departureTime;
  final double totalCost;
  final double userShare;
  final double savings;
  final String? status;
  final VehicleHistory? vehicle;
  final List<ParticipantHistory> participants;
  final int passengersCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  RideHistory({
    required this.id,
    required this.type,
    required this.startLocation,
    required this.endLocation,
    required this.distance,
    required this.departureTime,
    required this.totalCost,
    required this.userShare,
    required this.savings,
    required this.status,
    required this.vehicle,
    required this.participants,
    required this.passengersCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RideHistory.fromJson(Map<String, dynamic> json) {
    return RideHistory(
      id: json['id'] ?? 0,
      type: json['type']?.toString(),
      startLocation: json['startLocation']?.toString(),
      endLocation: json['endLocation']?.toString(),
      distance: (json['distance'] != null) ? (json['distance'] as num).toDouble() : 0.0,
      departureTime: DateTime.tryParse(json['departureTime'] ?? '') ?? DateTime.now(),
      totalCost: (json['totalCost'] != null) ? (json['totalCost'] as num).toDouble() : 0.0,
      userShare: (json['userShare'] != null) ? (json['userShare'] as num).toDouble() : 0.0,
      savings: (json['savings'] != null) ? (json['savings'] as num).toDouble() : 0.0,
      status: json['status']?.toString(),
      vehicle: json['vehicle'] != null ? VehicleHistory.fromJson(json['vehicle']) : null,
      participants: (json['participants'] as List<dynamic>?)?.map((p) => ParticipantHistory.fromJson(p)).toList() ?? [],
      passengersCount: json['passengersCount'] ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'startLocation': startLocation,
      'endLocation': endLocation,
      'distance': distance,
      'departureTime': departureTime.toIso8601String(),
      'totalCost': totalCost,
      'userShare': userShare,
      'savings': savings,
      'status': status,
      'vehicle': vehicle?.toJson(),
      'participants': participants.map((p) => p.toJson()).toList(),
      'passengersCount': passengersCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class VehicleHistory {
  final String? model;
  final String? brand;
  final String? plate;

  VehicleHistory({
    this.model,
    this.brand,
    this.plate,
  });

  factory VehicleHistory.fromJson(Map<String, dynamic> json) {
    return VehicleHistory(
      model: json['model']?.toString(),
      brand: json['brand']?.toString(),
      plate: json['plate']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'model': model,
      'brand': brand,
      'plate': plate,
    };
  }

  String get fullName {
    final parts = [if (brand != null) brand, if (model != null) model];
    return parts.join(' ');
  }
}

class ParticipantHistory {
  final String name;
  final String role;
  final double share;

  ParticipantHistory({
    required this.name,
    required this.role,
    required this.share,
  });

  factory ParticipantHistory.fromJson(Map<String, dynamic> json) {
    return ParticipantHistory(
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      share: (json['share'] != null) ? (json['share'] as num).toDouble() : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'role': role,
      'share': share,
    };
  }
}

class RideHistoryResponse {
  final List<RideHistory> rides;
  final int currentPage;
  final int totalItems;
  final int totalPages;

  RideHistoryResponse({
    required this.rides,
    required this.currentPage,
    required this.totalItems,
    required this.totalPages,
  });

  factory RideHistoryResponse.fromJson(Map<String, dynamic> json) {
    final dynamic rawList = json['rides/history'] ?? json['rides'] ?? [];
    final List<dynamic> ridesList = (rawList is List) ? rawList : <dynamic>[];
    final pageInfo = json['_page'] as Map<String, dynamic>? ?? {};
    
    return RideHistoryResponse(
      rides: ridesList.map((ride) => RideHistory.fromJson(ride)).toList(),
      currentPage: pageInfo['current'] ?? 1,
      totalItems: json['totalItems'] ?? 0,
      totalPages: pageInfo['total'] ?? 1,
    );
  }
}

// Extensão para adicionar getters úteis ao modelo RideHistory
extension RideHistoryExtensions on RideHistory {
  String get startAddress => startLocation ?? '';
  String get endAddress => endLocation ?? '';
  String get route => '${startLocation ?? ''} → ${endLocation ?? ''}';
  String? get title => type == 'driver' ? 'Motorista' : (type == 'passenger' ? 'Passageiro' : null);
  String get vehicleInfo {
    if (vehicle == null) return '';
    final name = [vehicle!.brand, vehicle!.model].where((e) => e != null && e!.isNotEmpty).join(' ');
    final plate = vehicle!.plate ?? '';
    if (name.isNotEmpty && plate.isNotEmpty) {
      return '$name - $plate';
    } else if (name.isNotEmpty) {
      return name;
    } else if (plate.isNotEmpty) {
      return plate;
    } else {
      return '';
    }
  }
  String get statusText {
    switch (status) {
      case 'completed':
        return 'Concluída';
      case 'cancelled':
        return 'Cancelada';
      case 'in_progress':
        return 'Em andamento';
      default:
        return status ?? '';
    }
  }
} 