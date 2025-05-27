class User {
  int? id;
  String name;
  String lastName;
  String email;
  String password;
  String cpf;
  String phone;
  String street;
  String cnh;
  String? cnhBackUrl;
  String? cnhFrontUrl;
  String? bpkLinkUrl;
  int number;
  String city;
  String zipcode;
  DateTime createdAt;
  DateTime? updatedAt;
  bool isDriver;
  bool isPassenger;
  bool verified;

  User({
    this.id,
    required this.name,
    required this.lastName,
    required this.email,
    required this.password,
    required this.cpf,
    required this.phone,
    required this.street,
    required this.cnh,
    this.cnhBackUrl,
    this.cnhFrontUrl,
    this.bpkLinkUrl,
    required this.number,
    required this.city,
    required this.zipcode,
    required this.createdAt,
    this.updatedAt,
    required this.isDriver,
    required this.isPassenger,
    required this.verified,
  });

  User.fromJson(Map<String, dynamic> json)
    : id = json['id'],
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
      verified = json['verified'] == 1;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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
      'createAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isDriver': isDriver ? 1 : 0,
      'isPassenger': isPassenger ? 1 : 0,
      'verified': verified ? 1 : 0,
    };
  }
}
