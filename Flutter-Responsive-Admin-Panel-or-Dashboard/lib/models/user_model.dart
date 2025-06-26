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
