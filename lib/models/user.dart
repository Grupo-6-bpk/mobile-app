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
    return {'id': id, 'cnhVerified': cnhVerified, 'active': active};
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
    return {'id': id, 'active': active};
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
  String? rgFrontUrl;
  String? rgBackUrl;
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
    this.rgFrontUrl,
    this.rgBackUrl,
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
      rgFrontUrl = json['rg_front']?.toString(),
      rgBackUrl = json['rg_back']?.toString(),
      bpkLinkUrl = json['bpk_link']?.toString(),
      number = json['number'] as int?,
      city = json['city']?.toString(),
      zipcode = json['zipcode']?.toString(),
      createdAt =
          json['createAt'] != null
              ? DateTime.tryParse(json['createAt'].toString())
              : null,
      updatedAt =
          json['updated_at'] != null
              ? DateTime.tryParse(json['updated_at'].toString())
              : null,
      isDriver = json['isDriver'] == 1 || json['isDriver'] == true,
      isPassenger = json['isPassenger'] == 1 || json['isPassenger'] == true,
      verified = json['verified'] == 1 || json['verified'] == true,
      avatarUrl = json['avatarUrl']?.toString(),
      driver = json['driver'] != null ? Driver.fromJson(json['driver']) : null,
      passenger =
          json['passenger'] != null
              ? Passenger.fromJson(json['passenger'])
              : null;  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    
    // Adiciona apenas campos que não são null
    data['name'] = name;
    if (lastName != null) data['last_name'] = lastName;
    if (email != null) data['email'] = email;
    if (password != null) data['password'] = password;
    if (cpf != null) data['cpf'] = cpf;
    if (phone != null) data['phone'] = phone;
    if (street != null) data['street'] = street;
    if (cnh != null) data['cnh'] = cnh;
    if (cnhBackUrl != null) data['cnh_back'] = cnhBackUrl;
    if (cnhFrontUrl != null) data['cnh_front'] = cnhFrontUrl;
    if (bpkLinkUrl != null) data['bpk_link'] = bpkLinkUrl;
    if (rgFrontUrl != null) data['rg_front'] = rgFrontUrl;
    if (rgBackUrl != null) data['rg_back'] = rgBackUrl;
    if (number != null) data['number'] = number;
    if (city != null) data['city'] = city;
    if (zipcode != null) data['zipcode'] = zipcode;
    if (createdAt != null) data['createAt'] = createdAt!.toIso8601String();
    if (updatedAt != null) data['updatedAt'] = updatedAt!.toIso8601String();
    if (isDriver != null) data['isDriver'] = isDriver;
    if (isPassenger != null) data['isPassenger'] = isPassenger;
    if (verified != null) data['verified'] = verified;
    if (avatarUrl != null) data['avatarUrl'] = avatarUrl;
    
    // Só inclui userId se não for null
    if (userId != null) {
      data['userId'] = userId;
    }
    
    // Só inclui driver/passenger se não forem null
    if (driver != null) {
      data['driver'] = driver!.toJson();
    }
    
    if (passenger != null) {
      data['passenger'] = passenger!.toJson();
    }
    
    return data;
  }
}
