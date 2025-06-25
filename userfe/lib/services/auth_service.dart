import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://localhost/MyProject/backendapi';
  static const String _userKey = 'user_data';
  static const String _roleKey = 'user_role';

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/login.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'Email': email,
          'MatKhau': password,
        }),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        
        // Lưu thông tin user nếu đăng nhập thành công
        if (result['success'] == 200 && result['user'] != null) {
          await _saveUserData(result['user']);
        }
        
        return result;
      } else {
        return {
          'success': false,
          'message': 'Lỗi kết nối server: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: $e',
      };
    }
  }

  static Future<void> _saveUserData(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user));
    await prefs.setString(_roleKey, user['Role'] ?? 'user');
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString(_userKey);
    if (userString != null) {
      return json.decode(userString);
    }
    return null;
  }

  static Future<String> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey) ?? 'user';
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_roleKey);
  }

  static Future<bool> isLoggedIn() async {
    final userData = await getUserData();
    return userData != null;
  }

  static Future<Map<String, dynamic>> register(String name, String email, String password, String phone) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/add_user.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'Ten': name,
          'Email': email,
          'MatKhau': password,
          'SoDienThoai': phone,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Lỗi kết nối server: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/get_products.php'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Lỗi kết nối server: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối 111: $e',
      };
    }
  }
} 