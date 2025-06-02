class User {
  int? userId;
  String name;
  String? lastName;
  String email;
  String? password;
  String? cpf;
  String phone;
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

  User({
    this.userId,
    required this.name,
    this.lastName,
    required this.email,
    this.password,
    this.cpf,
    required this.phone,
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
  });

  User.fromJson(Map<String, dynamic> json)
    : userId = json['userId'],
      name = json['name'],
      lastName = json['last_name'],
      email = json['email'],
      password = json['password'],
      cpf = json['cpf'],
      phone = json['phone'],
      street = json['street'],
      cnh = json['cnh'],
      cnhBackUrl = json['cnh_back'],
      cnhFrontUrl = json['cnh_front'],
      bpkLinkUrl = json['bpk_link'],
      number = json['number'],
      city = json['city'],
      zipcode = json['zipcode'],
      createdAt = DateTime.parse(json['createAt']),
      updatedAt =
          json['updated_at'] != null ? DateTime.parse(json['updatedAt']) : null,
      isDriver = json['isDriver'] == 1,
      isPassenger = json['isPassenger'] == 1,
      verified = json['verified'] == 1,
      avatarUrl = json['avatarUrl'] ?? '';

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
      'createAt': createdAt,
      'updatedAt': updatedAt?.toIso8601String(),
      'isDriver': isDriver,
      'isPassenger': isPassenger ,
      'verified': verified,
      'avatarUrl': avatarUrl,
    };
  }
}
