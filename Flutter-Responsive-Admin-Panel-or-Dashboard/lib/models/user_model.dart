class User {
  final int id;
  final String username;
  final String email;
  final String phone;
  final String? password;
  final String gender;
  final String role;
  final String createdAt;
  final String updatedAt;
  final String? dob;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.phone,
    this.password,
    required this.gender,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.dob,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      password: json['password'],
      gender: json['gender'] ?? '',
      role: json['role'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      dob: json['dob'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phone': phone,
      'password': password,
      'gender': gender,
      'role': role,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'dob': dob,
    };
  }
}

class UserAddress {
  final int id;
  final int userId;
  final String addressLine;
  final String city;
  final String province;
  final String? postalCode;
  final bool isDefault;
  final String createdAt;

  UserAddress({
    required this.id,
    required this.userId,
    required this.addressLine,
    required this.city,
    required this.province,
    this.postalCode,
    required this.isDefault,
    required this.createdAt,
  });

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is String && v.isNotEmpty) return int.tryParse(v) ?? 0;
      return 0;
    }
    return UserAddress(
      id: parseInt(json['id']),
      userId: parseInt(json['user_id']),
      addressLine: json['address_line'] ?? '',
      city: json['city'] ?? '',
      province: json['province'] ?? '',
      postalCode: json['postal_code'],
      isDefault: json['is_default'] == 1 || json['is_default'] == true,
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson({bool forUpdate = false}) => {
    if (forUpdate) 'address_id': id else 'id': id,
    'user_id': userId,
    'address_line': addressLine,
    'city': city,
    'province': province,
    'postal_code': postalCode,
    'is_default': isDefault ? 1 : 0,
    'created_at': createdAt,
  };

  UserAddress copyWith({
    int? id,
    int? userId,
    String? addressLine,
    String? city,
    String? province,
    String? postalCode,
    bool? isDefault,
    String? createdAt,
  }) {
    return UserAddress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      addressLine: addressLine ?? this.addressLine,
      city: city ?? this.city,
      province: province ?? this.province,
      postalCode: postalCode ?? this.postalCode,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
