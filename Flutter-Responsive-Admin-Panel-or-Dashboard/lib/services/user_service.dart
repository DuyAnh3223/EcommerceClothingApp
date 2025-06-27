import '../models/user_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserService {
  static Future<List<UserAddress>> getUserAddresses(int userId) async {
    final response = await http.get(Uri.parse('http://127.0.0.1/EcommerceClothingApp/API/users/get_user_addresses.php?user_id=$userId'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true && data['data'] is List) {
        return (data['data'] as List).map((e) => UserAddress.fromJson(e)).toList();
      }
    }
    throw Exception('Lỗi lấy địa chỉ');
  }

  static Future<bool> addUserAddress(UserAddress address) async {
    final response = await http.post(
      Uri.parse('http://127.0.0.1/EcommerceClothingApp/API/users/add_address.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(address.toJson()),
    );
    final data = json.decode(response.body);
    return data['success'] == true;
  }

  static Future<bool> updateUserAddress(UserAddress address) async {
    final response = await http.post(
      Uri.parse('http://127.0.0.1/EcommerceClothingApp/API/users/update_address.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(address.toJson(forUpdate: true)),
    );
    final data = json.decode(response.body);
    return data['success'] == true;
  }

  static Future<bool> deleteUserAddress(int addressId) async {
    final response = await http.post(
      Uri.parse('http://127.0.0.1/EcommerceClothingApp/API/users/delete_address.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'address_id': addressId}),
    );
    final data = json.decode(response.body);
    return data['success'] == true;
  }

  static Future<List<UserAddress>> getAllAddresses() async {
    final response = await http.get(Uri.parse('http://127.0.0.1/EcommerceClothingApp/API/users/get_all_addresses.php'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true && data['data'] is List) {
        return (data['data'] as List).map((e) => UserAddress.fromJson(e)).toList();
      }
    }
    throw Exception('Lỗi lấy tất cả địa chỉ');
  }
} 