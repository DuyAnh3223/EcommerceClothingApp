import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_combination_model.dart';

class VariantModel {
  final int variantId;
  final String sku;
  final double price;
  final int stock;
  final String imageUrl;
  final String status;
  final List<AttributeValue> attributeValues;

  VariantModel({
    required this.variantId,
    required this.sku,
    required this.price,
    required this.stock,
    required this.imageUrl,
    required this.status,
    required this.attributeValues,
  });

  factory VariantModel.fromJson(Map<String, dynamic> json) {
    return VariantModel(
      variantId: json['variant_id'],
      sku: json['sku'],
      price: (json['price'] as num).toDouble(),
      stock: json['stock'],
      imageUrl: json['image_url'] ?? '',
      status: json['status'],
      attributeValues: (json['attribute_values'] as List)
          .map((e) => AttributeValue.fromJson(e)).toList(),
    );
  }
}

class AttributeValue {
  final int attributeId;
  final String attributeName;
  final int valueId;
  final String value;

  AttributeValue({
    required this.attributeId,
    required this.attributeName,
    required this.valueId,
    required this.value,
  });

  factory AttributeValue.fromJson(Map<String, dynamic> json) {
    return AttributeValue(
      attributeId: json['attribute_id'],
      attributeName: json['attribute_name'],
      valueId: json['value_id'],
      value: json['value'],
    );
  }
}

class ProductCombinationService {
  static const String baseUrl = 'http://127.0.0.1/EcommerceClothingApp/API/product_combinations'; // Sửa lại domain khi deploy

  Future<List<ProductCombination>> getCombinations({int page = 1, int limit = 10}) async {
    final url = Uri.parse('$baseUrl/get_combinations.php?status=active&page=$page&limit=$limit');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true && data['data'] != null) {
        final List combos = data['data']['combinations'];
        return combos.map((e) => ProductCombination.fromJson(e)).toList();
      } else {
        throw Exception(data['message'] ?? 'Lỗi lấy tổ hợp sản phẩm');
      }
    } else {
      throw Exception('Lỗi server: ${response.statusCode}');
    }
  }

  Future<List<VariantModel>> getVariantsByProduct(int productId) async {
    final url = Uri.parse('$baseUrl/variants_attributes/get_variants.php?product_id=$productId');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true && data['variants'] != null) {
        final List variants = data['variants'];
        return variants.map((e) => VariantModel.fromJson(e)).toList();
      } else {
        throw Exception(data['message'] ?? 'Lỗi lấy biến thể');
      }
    } else {
      throw Exception('Lỗi server: ${response.statusCode}');
    }
  }

  // Thêm method để thêm combination vào giỏ hàng
  Future<Map<String, dynamic>> addCombinationToCart({
    required int userId,
    required int combinationId,
    required int quantity,
    required List<Map<String, dynamic>> items, // List of {productId, variantId, quantity}
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cart/add_combination_to_cart.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'user_id': userId,
          'combination_id': combinationId,
          'quantity': quantity,
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
} 