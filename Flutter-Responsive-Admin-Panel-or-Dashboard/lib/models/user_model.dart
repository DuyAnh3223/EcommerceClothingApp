class User {
  final String maND;
  final String ten;
  final String matKhau;
  final String soDienThoai;
  final String email;
  final String role; 

  User({
    required this.maND,
    required this.ten,
    required this.matKhau,
    required this.soDienThoai,
    required this.email,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      maND: json['MaND'].toString(),
      ten: json['Ten'],
      matKhau: json['MatKhau'],
      soDienThoai: json['SoDienThoai'],
      email: json['Email'],
      role: json['Role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'MaND': maND,
      'Ten': ten,
      'MatKhau': matKhau,
      'SoDienThoai': soDienThoai,
      'Email': email,
      'Role': role,
    };
  }
}
