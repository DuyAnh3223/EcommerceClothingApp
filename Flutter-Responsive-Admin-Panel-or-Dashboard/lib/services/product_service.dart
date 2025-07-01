import 'dart:convert';
import 'package:http/http.dart' as http;

class ProductService {
  static const String baseUrl = 'http://127.0.0.1/EcommerceClothingApp/API';

  static Future<Map<String, dynamic>> getProductsByUser(int userId) async {
    try {
      final uri = Uri.parse('$baseUrl/products/get_products.php?created_by=$userId');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'products': data['data'] ?? [],
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Unknown error',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'HTTP Error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }
} 