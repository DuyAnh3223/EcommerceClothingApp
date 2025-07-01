import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_combination_model.dart';

class ProductCombinationService {
  static const String baseUrl = 'http://127.0.0.1/EcommerceClothingApp/API';

  // Helper method to get headers with token
  static Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer your_token_here', // Replace with actual token
    };
  }

  // Lấy danh sách tổ hợp sản phẩm
  static Future<Map<String, dynamic>> getCombinations({
    String status = 'all',
    String creatorType = 'all',
    int? createdBy,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = {
        'status': status,
        'creator_type': creatorType,
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (createdBy != null) {
        queryParams['created_by'] = createdBy.toString();
      }

      final uri = Uri.parse('$baseUrl/product_combinations/get_combinations.php')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: _getHeaders());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final combinations = (data['data']['combinations'] as List)
              .map((combination) => ProductCombination.fromJson(combination))
              .toList();
          
          return {
            'success': true,
            'combinations': combinations,
            'total': data['data']['total'],
            'page': data['data']['page'],
            'limit': data['data']['limit'],
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

  // Tạo tổ hợp sản phẩm mới
  static Future<Map<String, dynamic>> createCombination({
    required String name,
    String? description,
    String? imageUrl,
    double? discountPrice,
    String status = 'active',
    required int createdBy,
    required String creatorType,
    required List<String> categories,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      print(json.encode({
        'name': name,
        'description': description,
        'image_url': imageUrl,
        'discount_price': discountPrice,
        'status': status,
        'created_by': createdBy,
        'creator_type': creatorType,
        'categories': categories,
        'items': items,
      }));

      final response = await http.post(
        Uri.parse('$baseUrl/product_combinations/create_combination.php'),
        headers: _getHeaders(),
        body: json.encode({
          'name': name,
          'description': description,
          'image_url': imageUrl,
          'discount_price': discountPrice,
          'status': status,
          'created_by': createdBy,
          'creator_type': creatorType,
          'categories': categories,
          'items': items,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? 'Unknown response',
          'data': data['data'],
        };
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

  // Lấy tổ hợp sản phẩm theo ID
  static Future<Map<String, dynamic>> getCombinationById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/product_combinations/get_combination.php?id=$id'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final combination = ProductCombination.fromJson(data['data']);
          return {
            'success': true,
            'combination': combination,
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

  // Cập nhật tổ hợp sản phẩm
  static Future<Map<String, dynamic>> updateCombination({
    required int id,
    String? name,
    String? description,
    String? imageUrl,
    double? discountPrice,
    String? status,
    List<String>? categories,
    List<Map<String, dynamic>>? items,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/product_combinations/update_combination.php'),
        headers: _getHeaders(),
        body: json.encode({
          'id': id,
          'name': name,
          'description': description,
          'image_url': imageUrl,
          'discount_price': discountPrice,
          'status': status,
          'categories': categories,
          'items': items,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? 'Unknown response',
          'data': data['data'],
        };
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

  // Xóa tổ hợp sản phẩm
  static Future<Map<String, dynamic>> deleteCombination(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/product_combinations/delete_combination.php'),
        headers: _getHeaders(),
        body: json.encode({'id': id}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? 'Unknown response',
        };
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

  // Lấy thống kê tổ hợp sản phẩm
  static Future<Map<String, dynamic>> getCombinationStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/product_combinations/get_stats.php'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'stats': data['data'],
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