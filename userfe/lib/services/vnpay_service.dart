import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class VNPayService {
  static const String baseUrl = 'http://127.0.0.1/EcommerceClothingApp/API';

  // Tạo thanh toán VNPAY - Sử dụng API đã fix
  static Future<Map<String, dynamic>> createPayment({
    required int orderId,
    required double amount,
    required int userId,
    String? orderInfo,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
  }) async {
    try {
      print('VNPAY: Creating payment for order #$orderId, amount: $amount');
      print('VNPAY: Using fixed API endpoint');
      
      final response = await http.post(
        Uri.parse('$baseUrl/vnpay_php/create_vnpay_payment_fixed.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'order_id': orderId,
          'amount': amount,
          'user_id': userId,
          'order_info': orderInfo ?? 'Thanh toán đơn hàng #$orderId',
          'customer_name': customerName,
          'customer_phone': customerPhone,
          'customer_email': customerEmail,
        }),
      );

      print('VNPAY: Response status: ${response.statusCode}');
      print('VNPAY: Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final result = json.decode(response.body);
          print('VNPAY: Parsed response: $result');
          
          // Kiểm tra response format mới
          if (result['success'] == true) {
            // Trả về format tương thích với code hiện tại
            return {
              'success': true,
              'payment_url': result['paymentUrl'] ?? result['data']['payment_url'],
              'transaction_ref': result['transactionRef'] ?? result['data']['order_id'],
              'message': result['message'] ?? 'Payment URL created successfully',
              'debug': result['data']['debug'] ?? {},
            };
          } else {
            return {
              'success': false,
              'message': result['error'] ?? result['message'] ?? 'Unknown error',
              'debug': result['data'] ?? {},
            };
          }
        } catch (jsonError) {
          print('VNPAY: JSON parsing error: $jsonError');
          print('VNPAY: Raw response body: ${response.body}');
          throw Exception('Invalid JSON response from server: ${response.body.substring(0, 100)}...');
        }
      } else {
        print('VNPAY: HTTP error ${response.statusCode}: ${response.body}');
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('VNPAY: Exception: $e');
      throw Exception('VNPAY Error: $e');
    }
  }

  // Tạo thanh toán VNPAY cho testing (không cần user_id)
  static Future<Map<String, dynamic>> createTestPayment({
    required String orderId,
    required double amount,
    String? orderInfo,
    String? returnUrl,
  }) async {
    try {
      print('VNPAY: Creating test payment for order #$orderId, amount: $amount');
      
      final response = await http.post(
        Uri.parse('$baseUrl/vnpay_php/create_vnpay_payment_fixed.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'orderId': orderId,
          'amount': amount.toInt(),
          'orderDesc': orderInfo ?? 'Test payment for order #$orderId',
          'returnUrl': returnUrl,
        }),
      );

      print('VNPAY: Test response status: ${response.statusCode}');
      print('VNPAY: Test response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final result = json.decode(response.body);
          print('VNPAY: Test parsed response: $result');
          return result;
        } catch (jsonError) {
          print('VNPAY: Test JSON parsing error: $jsonError');
          throw Exception('Invalid JSON response from test API: ${response.body.substring(0, 100)}...');
        }
      } else {
        print('VNPAY: Test HTTP error ${response.statusCode}: ${response.body}');
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('VNPAY: Test Exception: $e');
      throw Exception('VNPAY Test Error: $e');
    }
  }

  // Test API connection
  static Future<Map<String, dynamic>> testConnection() async {
    try {
      print('VNPAY: Testing API connection...');
      
      final response = await http.post(
        Uri.parse('$baseUrl/vnpay_php/create_vnpay_payment_fixed.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'test',
          'orderId': 'TEST_CONNECTION',
          'amount': 1000,
          'orderDesc': 'Connection test'
        }),
      );

      print('VNPAY: Test connection response status: ${response.statusCode}');
      print('VNPAY: Test connection response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final result = json.decode(response.body);
          print('VNPAY: Test connection parsed response: $result');
          return result;
        } catch (jsonError) {
          throw Exception('Invalid JSON response from test API: ${response.body.substring(0, 100)}...');
        }
      } else {
        throw Exception('Test API failed: ${response.statusCode}');
      }
    } catch (e) {
      print('VNPAY: Test connection error: $e');
      throw Exception('Test connection error: $e');
    }
  }

  // Get server information
  static Future<Map<String, dynamic>> getServerInfo() async {
    try {
      print('VNPAY: Getting server information...');
      
      final response = await http.post(
        Uri.parse('$baseUrl/vnpay_php/create_vnpay_payment_fixed.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'server_info'
        }),
      );

      print('VNPAY: Server info response status: ${response.statusCode}');
      print('VNPAY: Server info response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final result = json.decode(response.body);
          print('VNPAY: Server info parsed response: $result');
          return result;
        } catch (jsonError) {
          throw Exception('Invalid JSON response from server info API: ${response.body.substring(0, 100)}...');
        }
      } else {
        throw Exception('Server info API failed: ${response.statusCode}');
      }
    } catch (e) {
      print('VNPAY: Server info error: $e');
      throw Exception('Server info error: $e');
    }
  }

  // Kiểm tra trạng thái thanh toán
  static Future<Map<String, dynamic>> checkPaymentStatus({
    required int orderId,
    required int userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/vnpay_php/check_payment_status.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'order_id': orderId,
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        try {
          return json.decode(response.body);
        } catch (jsonError) {
          throw Exception('Invalid JSON response from server: ${response.body.substring(0, 100)}...');
        }
      } else {
        throw Exception('Failed to check payment status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Mở URL thanh toán
  static Future<void> openPaymentUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch payment URL');
    }
  }

  // Mở URL thanh toán trong WebView
  static Future<void> openPaymentUrlInWebView(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.inAppWebView);
    } else {
      throw Exception('Could not launch payment URL');
    }
  }

  // Debug helper - Log current configuration
  static void logConfiguration() {
    print('VNPAY: Current configuration:');
    print('VNPAY: Base URL: $baseUrl');
    print('VNPAY: Payment API: $baseUrl/vnpay_php/create_vnpay_payment_fixed.php');
    print('VNPAY: Return API: $baseUrl/vnpay_php/vnpay_return.php');
    print('VNPAY: Status API: $baseUrl/vnpay_php/check_payment_status.php');
  }
} 