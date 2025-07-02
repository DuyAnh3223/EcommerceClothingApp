import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_combination_model.dart';

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
} 