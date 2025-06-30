import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/agency_product_model.dart';

class AgencyService {
  static const String baseUrl = 'http://127.0.0.1/EcommerceClothingApp/API'; //
  
  // Get agency products
  static Future<Map<String, dynamic>> getProducts({
    String status = 'all',
    int page = 1,
    int limit = 10,
    String? token,
  }) async {
    try {
      final url = '$baseUrl/agency/get_products.php?status=$status&page=$page&limit=$limit';
      print('DEBUG: Calling API: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print('DEBUG: Response status: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final products = (data['data']['products'] as List)
              .map((json) => AgencyProduct.fromJson(json))
              .toList();
          
          return {
            'success': true,
            'products': products,
            'pagination': data['data']['pagination'],
          };
        } else {
          return {
            'success': false,
            'message': data['message'],
          };
        }
      } else {
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('DEBUG: Exception caught: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Add new product
  static Future<Map<String, dynamic>> addProduct({
    required String name,
    required String description,
    required String category,
    required String genderTarget,
    String? mainImage,
    required List<Map<String, dynamic>> variants,
    String? token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/agency/add_product.php'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'name': name,
          'description': description,
          'category': category,
          'gender_target': genderTarget,
          'main_image': mainImage,
          'variants': variants,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'],
          'product_id': data['data']['product_id'],
        };
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to add product',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // Get attributes
  static Future<Map<String, dynamic>> getAttributes({
    String? token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/agency/get_attributes.php'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final attributes = (data['data']['attributes'] as List)
              .map((json) => Attribute.fromJson(json))
              .toList();
          
          return {
            'success': true,
            'attributes': attributes,
          };
        } else {
          return {
            'success': false,
            'message': data['message'],
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to load attributes',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // Get attribute values
  static Future<Map<String, dynamic>> getAttributeValues({
    required int attributeId,
    String? token,
  }) async {
    try {
      final url = '$baseUrl/agency/get_attribute_values.php?attribute_id=$attributeId';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return {
            'success': true,
            'values': data['data']['values'],
          };
        } else {
          return {
            'success': false,
            'message': data['message'],
          };
        }
      } else {
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Delete attribute
  static Future<Map<String, dynamic>> deleteAttribute({
    required int attributeId,
    String? token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/agency/delete_attribute.php'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'attribute_id': attributeId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete attribute',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // Delete attribute value
  static Future<Map<String, dynamic>> deleteAttributeValue({
    required int valueId,
    String? token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/agency/delete_attribute_value.php'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'value_id': valueId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete attribute value',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // Get product variants
  static Future<Map<String, dynamic>> getProductVariants({
    required int productId,
    String? token,
  }) async {
    try {
      final url = '$baseUrl/agency/get_product_variants.php?product_id=$productId';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return {
            'success': true,
            'variants': data['data']['variants'],
            'product': data['data']['product'],
          };
        } else {
          return {
            'success': false,
            'message': data['message'],
          };
        }
      } else {
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get all variants
  static Future<Map<String, dynamic>> getAllVariants({
    String? token,
  }) async {
    try {
      final url = '$baseUrl/agency/get_all_variants.php';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return {
            'success': true,
            'variants': data['data']['variants'],
          };
        } else {
          return {
            'success': false,
            'message': data['message'],
          };
        }
      } else {
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Delete variant
  static Future<Map<String, dynamic>> deleteVariant({
    required int variantId,
    String? token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/agency/delete_variant.php'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'variant_id': variantId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete variant',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // Delete product
  static Future<Map<String, dynamic>> deleteProduct({
    required int productId,
    String? token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/agency/delete_product.php'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'product_id': productId,
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete product',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // Submit product for approval
  static Future<Map<String, dynamic>> submitForApproval({
    required int productId,
    String? token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/agency/submit_for_approval.php'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'product_id': productId,
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to submit for approval',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // Add attribute
  static Future<Map<String, dynamic>> addAttribute({
    required String name,
    String? token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/agency/add_attribute.php'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'name': name,
        }),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'],
          'attribute_id': data['data']?['attribute_id'],
        };
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to add attribute',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // Add attribute value
  static Future<Map<String, dynamic>> addAttributeValue({
    required int attributeId,
    required String value,
    String? token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/agency/add_attribute_value.php'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'attribute_id': attributeId,
          'value': value,
        }),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'],
          'value_id': data['data']?['value_id'],
        };
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to add attribute value',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // Update product
  static Future<Map<String, dynamic>> updateProduct({
    required int productId,
    required String name,
    required String description,
    required String category,
    required String genderTarget,
    String? mainImage,
    required List<Map<String, dynamic>> variants,
    String? token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/agency/update_product.php'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'product_id': productId,
          'name': name,
          'description': description,
          'category': category,
          'gender_target': genderTarget,
          'main_image': mainImage,
          'variants': variants,
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update product',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
} 