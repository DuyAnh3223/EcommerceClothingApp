import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/agency_product_model.dart';

class AgencyService {
  static const String baseUrl = 'http://127.0.0.1/EcommerceClothingApp/API/agency';

  // Helper method to get headers with token
  static Map<String, String> _getHeaders() {
    // In a real app, you would get the token from secure storage
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer your_token_here', // Replace with actual token
    };
  }

  // Lấy danh sách sản phẩm của agency
  static Future<Map<String, dynamic>> getProducts({String? status}) async {
    try {
      String url = '$baseUrl/products/get_products.php';
      if (status != null && status != 'all') {
        url += '?status=$status';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          final productsData = data['data']['products'] as List;
          
          final products = productsData
              .map((product) => AgencyProduct.fromJson(product))
              .toList();
          
          return {
            'success': true,
            'products': products,
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

  // Thêm sản phẩm mới
  static Future<Map<String, dynamic>> addProduct({
    required String name,
    required String description,
    required String category,
    required String genderTarget,
    String? mainImage,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/products/add_product.php'),
        headers: _getHeaders(),
        body: json.encode({
          'name': name,
          'description': description,
          'category': category,
          'gender_target': genderTarget,
          'main_image': mainImage,
        }),
      );

      if (response.statusCode == 201) {
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

  // Cập nhật sản phẩm
  static Future<Map<String, dynamic>> updateProduct({
    required int productId,
    String? name,
    String? description,
    String? category,
    String? genderTarget,
    String? mainImage,
  }) async {
    try {
      final body = <String, dynamic>{'product_id': productId};
      if (name != null) body['name'] = name;
      if (description != null) body['description'] = description;
      if (category != null) body['category'] = category;
      if (genderTarget != null) body['gender_target'] = genderTarget;
      if (mainImage != null) body['main_image'] = mainImage;

      final response = await http.put(
        Uri.parse('$baseUrl/products/update_product.php'),
        headers: _getHeaders(),
        body: json.encode(body),
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

  // Xóa sản phẩm
  static Future<Map<String, dynamic>> deleteProduct(int productId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/products/delete_product.php'),
        headers: _getHeaders(),
        body: json.encode({'product_id': productId}),
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

  // Lấy danh sách thuộc tính
  static Future<Map<String, dynamic>> getAttributes() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/variants_attributes/get_attributes.php'),
        headers: _getHeaders(),
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

  // Thêm thuộc tính mới
  static Future<Map<String, dynamic>> addAttribute(String name) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/variants_attributes/add_attribute.php'),
        headers: _getHeaders(),
        body: json.encode({'name': name}),
      );

      if (response.statusCode == 201) {
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

  // Thêm giá trị thuộc tính
  static Future<Map<String, dynamic>> addAttributeValue({
    required int attributeId,
    required String value,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/variants_attributes/add_attribute_value.php'),
        headers: _getHeaders(),
        body: json.encode({
          'attribute_id': attributeId,
          'value': value,
        }),
      );

      if (response.statusCode == 201) {
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

  // Lấy danh sách biến thể
  static Future<Map<String, dynamic>> getVariants({int? productId}) async {
    try {
      String url = '$baseUrl/variants_attributes/get_variants.php';
      if (productId != null) {
        url += '?product_id=$productId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? 'Unknown response',
          'data': data['data'] ?? data, // Fallback to full response if no 'data' field
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

  // Thêm variant mới
  static Future<Map<String, dynamic>> addVariant({
    required int productId,
    required String sku,
    required double price,
    required int stock,
    required List<int> attributeValueIds,
    String? imageUrl,
  }) async {
    try {
      final body = {
        'product_id': productId,
        'sku': sku,
        'price': price,
        'stock': stock,
        'attribute_values': attributeValueIds,
      };
      
      if (imageUrl != null) {
        body['image_url'] = imageUrl;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/variants_attributes/add_variant.php'),
        headers: _getHeaders(),
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
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

  // Gửi sản phẩm để duyệt
  static Future<Map<String, dynamic>> submitForApproval(int productId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/submit_for_approval.php'),
        headers: _getHeaders(),
        body: json.encode({'product_id': productId}),
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

  // Lấy danh sách giá trị thuộc tính
  static Future<Map<String, dynamic>> getAttributeValues(int attributeId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/variants_attributes/get_attribute_values.php?attribute_id=$attributeId'),
        headers: _getHeaders(),
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

  // Xóa thuộc tính
  static Future<Map<String, dynamic>> deleteAttribute(int attributeId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/variants_attributes/delete_attribute.php'),
        headers: _getHeaders(),
        body: json.encode({'attribute_id': attributeId}),
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

  // Xóa giá trị thuộc tính
  static Future<Map<String, dynamic>> deleteAttributeValue(int valueId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/variants_attributes/delete_attribute_value.php'),
        headers: _getHeaders(),
        body: json.encode({'value_id': valueId}),
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

  // Lấy danh sách variants của sản phẩm (alias for getVariants)
  static Future<Map<String, dynamic>> getProductVariants(int productId) async {
    return getVariants(productId: productId);
  }

  // Lấy tất cả variants
  static Future<Map<String, dynamic>> getAllVariants() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/variants_attributes/get_variants.php'),
        headers: _getHeaders(),
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

  // Xóa variant
  static Future<Map<String, dynamic>> deleteVariant(int variantId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/variants_attributes/delete_variant.php'),
        headers: _getHeaders(),
        body: json.encode({'variant_id': variantId}),
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

  // Cập nhật variant
  static Future<Map<String, dynamic>> updateVariant({
    required int variantId,
    required String sku,
    required double price,
    required int stock,
    required List<int> attributeValueIds,
    String? imageUrl,
  }) async {
    try {
      final body = {
        'variant_id': variantId,
        'sku': sku,
        'price': price,
        'stock': stock,
        'attribute_value_ids': attributeValueIds,
      };
      
      if (imageUrl != null) {
        body['image_url'] = imageUrl;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/variants_attributes/update_variant.php'),
        headers: _getHeaders(),
        body: json.encode(body),
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
} 