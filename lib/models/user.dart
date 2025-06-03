class Driver {
  int? id;
  bool? cnhVerified;
  bool? active;

  Driver({
    this.id,
    this.cnhVerified,
    this.active,
  });

  Driver.fromJson(Map<String, dynamic> json)
    : id = json['id'] as int?,
      cnhVerified = json['cnhVerified'] == 1 || json['cnhVerified'] == true,
      active = json['active'] == 1 || json['active'] == true;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cnhVerified': cnhVerified,
      'active': active,
    };
  }
}

class Passenger {
  int? id;
  bool? active;

  Passenger({
    this.id,
    this.active,
  });

  Passenger.fromJson(Map<String, dynamic> json)
    : id = json['id'] as int?,
      active = json['active'] == 1 || json['active'] == true;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'active': active,
    };
  }
}

class User {
  int? userId;
  String name;
  String? lastName;
  String? email;
  String? password;
  String? cpf;
  String? phone;
  String? street;
  String? cnh;
  String? cnhBackUrl;
  String? cnhFrontUrl;
  String? bpkLinkUrl;
  int? number;
  String? city;
  String? zipcode;
  DateTime? createdAt;
  DateTime? updatedAt;
  bool? isDriver;
  bool? isPassenger;
  bool? verified;
  String? avatarUrl;
  Driver? driver;
  Passenger? passenger;

  User({
    this.userId,
    required this.name,
    this.lastName,
    this.email,
    this.password,
    this.cpf,
    this.phone,
    this.street,
    this.cnh,
    this.cnhBackUrl,
    this.cnhFrontUrl,
    this.bpkLinkUrl,
    this.number,
    this.city,
    this.zipcode,
    this.createdAt,
    this.updatedAt,
    this.isDriver,
    this.isPassenger,
    this.verified,
    this.avatarUrl,
    this.driver,
    this.passenger,
  });

  User.fromJson(Map<String, dynamic> json)
    : userId = json['userId'] as int? ?? json['id'] as int?,
      name = json['name']?.toString() ?? '',
      lastName = json['last_name']?.toString(),
      email = json['email']?.toString(),
      password = json['password']?.toString(),
      cpf = json['cpf']?.toString(),
      phone = json['phone']?.toString(),
      street = json['street']?.toString(),
      cnh = json['cnh']?.toString(),
      cnhBackUrl = json['cnh_back']?.toString(),
      cnhFrontUrl = json['cnh_front']?.toString(),
      bpkLinkUrl = json['bpk_link']?.toString(),
      number = json['number'] as int?,
      city = json['city']?.toString(),
      zipcode = json['zipcode']?.toString(),
      createdAt = json['createAt'] != null ? DateTime.tryParse(json['createAt'].toString()) : null,
      updatedAt = json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      isDriver = json['isDriver'] == 1 || json['isDriver'] == true,
      isPassenger = json['isPassenger'] == 1 || json['isPassenger'] == true,
      verified = json['verified'] == 1 || json['verified'] == true,
      avatarUrl = json['avatarUrl']?.toString(),
      driver = json['driver'] != null ? Driver.fromJson(json['driver']) : null,
      passenger = json['passenger'] != null ? Passenger.fromJson(json['passenger']) : null;

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'last_name': lastName,
      'email': email,
      'password': password,
      'cpf': cpf,
      'phone': phone,
      'street': street,
      'cnh': cnh,
      'cnh_back': cnhBackUrl,
      'cnh_front': cnhFrontUrl,
      'bpk_link': bpkLinkUrl,
      'number': number,
      'city': city,
      'zipcode': zipcode,
      'createAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isDriver': isDriver,
      'isPassenger': isPassenger,
      'verified': verified,
      'avatarUrl': avatarUrl,
      'driver': driver?.toJson(),
      'passenger': passenger?.toJson(),
    };
  }
}
