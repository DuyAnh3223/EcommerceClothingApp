import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://127.0.0.1/EcommerceClothingApp/API';
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
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        
        // Lưu thông tin user nếu đăng nhập thành công
        if (result['success'] == true && result['user'] != null) {
          await saveUserData(result['user']);
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

  static Future<Map<String, dynamic>> userLogin(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/user_login.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        
        // Lưu thông tin user nếu đăng nhập thành công
        if (result['success'] == true && result['user'] != null) {
          await saveUserData(result['user']);
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

  static Future<void> saveUserData(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user));
    await prefs.setString(_roleKey, user['role'] ?? 'user');
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

  static Future<Map<String, dynamic>> serverLogout() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/logout.php'),
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
        'message': 'Lỗi kết nối: $e',
      };
    }
  }

  static Future<bool> isLoggedIn() async {
    final userData = await getUserData();
    return userData != null;
  }

  // Get current user data as a User object
  static Future<Map<String, dynamic>> getCurrentUser() async {
    final userData = await getUserData();
    if (userData != null) {
      return userData;
    }
    throw Exception('User not logged in');
  }

  static Future<Map<String, dynamic>> register(String username, String email, String password, String phone) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/add_user.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
          'phone': phone,
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
        'message': 'Lỗi kết nối: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> addToCart({
    required int userId,
    required int productId,
    required int variantId,
    int quantity = 1,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cart/add_to_cart.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'user_id': userId,
          'product_id': productId,
          'variant_id': variantId,
          'quantity': quantity,
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

  static Future<Map<String, dynamic>> getCart({
    required int userId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cart/get_cart.php?user_id=$userId'),
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
        'message': 'Lỗi kết nối: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> updateCart({
    required int cartItemId,
    required int quantity,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cart/update_cart.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'cart_item_id': cartItemId,
          'quantity': quantity,
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

  static Future<Map<String, dynamic>> deleteCartItem({
    required int cartItemId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cart/delete_cart_item.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'cart_item_id': cartItemId,
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

  static Future<Map<String, dynamic>> getUserAddresses({
    required int userId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/get_user_addresses.php?user_id=$userId'),
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
        'message': 'Lỗi kết nối: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> placeOrder({
    required int userId,
    required int productId,
    required int variantId,
    required int quantity,
    required int addressId,
    required String paymentMethod,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders/place_order.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'user_id': userId,
          'product_id': productId,
          'variant_id': variantId,
          'quantity': quantity,
          'address_id': addressId,
          'payment_method': paymentMethod,
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

  static Future<Map<String, dynamic>> placeOrderMulti({
    required int userId,
    required int addressId,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders/place_order_multi.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'address_id': addressId,
          'payment_method': paymentMethod,
          'items': items,
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

  static Future<Map<String, dynamic>> placeOrderWithCombinations({
    required int userId,
    required int addressId,
    required String paymentMethod,
    required List<Map<String, dynamic>> cartItems,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders/place_order_with_combinations.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'address_id': addressId,
          'payment_method': paymentMethod,
          'cart_items': cartItems,
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

  // Profile Management Methods
  static Future<Map<String, dynamic>> updateUserProfile({
    required int userId,
    String? username,
    String? email,
    String? phone,
    String? gender,
    String? dob,
  }) async {
    try {
      final Map<String, dynamic> body = {'user_id': userId};
      if (username != null) body['username'] = username;
      if (email != null) body['email'] = email;
      if (phone != null) body['phone'] = phone;
      if (gender != null) body['gender'] = gender;
      if (dob != null) body['dob'] = dob;

      final response = await http.post(
        Uri.parse('$baseUrl/users/update_user.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        
        // Update local user data if successful
        if (result['success'] == true && result['data'] != null) {
          await saveUserData(result['data']);
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

  static Future<Map<String, dynamic>> addAddress({
    required int userId,
    required String addressLine,
    required String city,
    required String province,
    String? postalCode,
    bool isDefault = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/add_address.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'user_id': userId,
          'address_line': addressLine,
          'city': city,
          'province': province,
          'postal_code': postalCode,
          'is_default': isDefault,
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

  static Future<Map<String, dynamic>> updateAddress({
    required int userId,
    required int addressId,
    String? addressLine,
    String? city,
    String? province,
    String? postalCode,
    bool? isDefault,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'user_id': userId,
        'address_id': addressId,
      };
      if (addressLine != null) body['address_line'] = addressLine;
      if (city != null) body['city'] = city;
      if (province != null) body['province'] = province;
      if (postalCode != null) body['postal_code'] = postalCode;
      if (isDefault != null) body['is_default'] = isDefault;

      final response = await http.post(
        Uri.parse('$baseUrl/users/update_address.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
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

  static Future<Map<String, dynamic>> deleteAddress({
    required int userId,
    required int addressId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/delete_address.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'user_id': userId,
          'address_id': addressId,
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

  static Future<Map<String, dynamic>> getUser({
    required int userId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/get_user.php?user_id=$userId'),
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
        'message': 'Lỗi kết nối: $e',
      };
    }
  }

  static Future<double> getCoinBalance({required int userId}) async {
    final response = await http.get(Uri.parse('http://localhost/EcommerceClothingApp/API/coin/get_balance.php?user_id=$userId'));
    final data = json.decode(response.body);
    if (data['success'] == true && data['balance'] != null) {
      return double.tryParse(data['balance'].toString()) ?? 0.0;
    }
    return 0.0;
  }

  static Future<List<Map<String, dynamic>>> getCoinTransactions({required int userId}) async {
    final response = await http.get(Uri.parse('http://localhost/EcommerceClothingApp/API/coin/get_card_transactions.php?user_id=$userId'));
    final data = json.decode(response.body);
    if (data['success'] == true && data['transactions'] != null) {
      return List<Map<String, dynamic>>.from(data['transactions']);
    }
    return [];
  }
} 