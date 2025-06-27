import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentService {
  static const String baseUrl = 'http://localhost/EcommerceClothingApp/API';

  static Future<Map<String, dynamic>> getPayments({
    required int userId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/payments/get_payments.php').replace(queryParameters: {
        'user_id': userId.toString(),
        'page': page.toString(),
        'limit': limit.toString(),
      });
      final response = await http.get(uri, headers: {
        'Content-Type': 'application/json',
      });
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Lỗi server: ${response.statusCode}',
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