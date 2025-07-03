import 'dart:convert';
import 'package:http/http.dart' as http;

class OrderService {
  static const String baseUrl = 'http://localhost/EcommerceClothingApp/API';

  // Lấy danh sách đơn hàng đã bán cho agency
  static Future<Map<String, dynamic>> getAgencyOrders({required int agencyId}) async {
    try {
      final uri = Uri.parse('$baseUrl/orders/get_agency_orders.php?agency_id=$agencyId');
      final response = await http.get(uri, headers: {
        'Content-Type': 'application/json',
      });
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Lỗi kết nối server: \\${response.statusCode}',
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