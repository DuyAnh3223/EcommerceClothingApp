import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

class ProductService {
  static const String baseUrl = 'http://127.0.0.1/EcommerceClothingApp/API';

  static Future<List<Product>> getProducts() async {
    try {
      final uri = Uri.parse('$baseUrl/products/get_products.php');
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> productsData = data['data'] ?? [];
          return productsData.map((productData) => Product.fromJson(productData)).toList();
        } else {
          throw Exception(data['message'] ?? 'Unknown error');
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

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