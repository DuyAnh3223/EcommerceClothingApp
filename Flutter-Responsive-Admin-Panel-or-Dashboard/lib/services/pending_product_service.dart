import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pending_product_model.dart';

class PendingProductService {
  static const String baseUrl = 'http://localhost/EcommerceClothingApp/API';

  // Helper method to get headers with token
  static Map<String, String> _getHeaders() {
    // In a real app, you would get the token from secure storage
    // For now, we'll use a placeholder
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer your_token_here', // Replace with actual token
    };
  }

  // Lấy danh sách sản phẩm theo status
  static Future<Map<String, dynamic>> getProductsByStatus(String status) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/get_pending_products.php?status=$status'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final products = (data['data']['products'] as List)
              .map((product) => PendingProduct.fromJson(product))
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

  // Duyệt sản phẩm (approve/reject)
  static Future<Map<String, dynamic>> reviewProduct({
    required int productId,
    required String action, // 'approve' or 'reject'
    String? reviewNotes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/review_agency_product.php'),
        headers: _getHeaders(),
        body: json.encode({
          'product_id': productId,
          'action': action,
          'review_notes': reviewNotes ?? '',
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

  // Lấy tổng số sản phẩm theo từng status
  static Future<Map<String, int>> getProductCounts() async {
    try {
      final pendingResponse = await getProductsByStatus('pending');
      final approvedResponse = await getProductsByStatus('approved');
      final rejectedResponse = await getProductsByStatus('rejected');

      return {
        'pending': pendingResponse['success'] ? pendingResponse['total'] : 0,
        'approved': approvedResponse['success'] ? approvedResponse['total'] : 0,
        'rejected': rejectedResponse['success'] ? rejectedResponse['total'] : 0,
      };
    } catch (e) {
      return {
        'pending': 0,
        'approved': 0,
        'rejected': 0,
      };
    }
  }
} 