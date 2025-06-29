import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class VNPayService {
  static const String baseUrl = 'http://127.0.0.1/EcommerceClothingApp/API';

  // Tạo thanh toán VNPAY
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
      final response = await http.post(
        Uri.parse('$baseUrl/vnpay_php/create_vnpay_payment.php'),
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

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create payment');
      }
    } catch (e) {
      throw Exception('Error: $e');
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
        return json.decode(response.body);
      } else {
        throw Exception('Failed to check payment status');
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
} 