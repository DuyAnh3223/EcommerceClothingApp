# Hướng dẫn tích hợp VNPAY với Flutter App

## Tổng quan
Hệ thống VNPAY đã được cập nhật để tích hợp với ứng dụng e-commerce Flutter. Các API đã được tối ưu hóa cho mobile app.

## Các API có sẵn

### 1. Tạo thanh toán VNPAY
**Endpoint:** `POST /create_vnpay_payment.php`

**Request Body:**
```json
{
    "order_id": 123,
    "amount": 500000,
    "user_id": 4,
    "order_info": "Thanh toán đơn hàng quần áo",
    "customer_name": "Nguyễn Văn A",
    "customer_phone": "0967586754",
    "customer_email": "user@gmail.com"
}
```

**Response:**
```json
{
    "success": true,
    "code": "00",
    "message": "Payment URL created successfully",
    "data": {
        "payment_url": "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html?...",
        "order_id": 123,
        "amount": 500000,
        "expire_date": "20250628143000",
        "order_info": "Thanh toán đơn hàng quần áo"
    }
}
```

### 2. Kiểm tra trạng thái thanh toán
**Endpoint:** `POST /check_payment_status.php`

**Request Body:**
```json
{
    "order_id": 123,
    "user_id": 4
}
```

**Response:**
```json
{
    "success": true,
    "data": {
        "order_id": 123,
        "total_amount": 500000,
        "order_status": "confirmed",
        "payment_status": "paid",
        "payment_method": "VNPAY",
        "transaction_code": "VNPAY123456789",
        "order_date": "2025-06-28 12:00:00",
        "paid_at": "2025-06-28 12:05:00",
        "is_paid": true,
        "is_confirmed": true
    }
}
```

## Tích hợp với Flutter

### 1. Thêm dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  url_launcher: ^6.2.1
  webview_flutter: ^4.4.2
```

### 2. Tạo service class cho VNPAY
```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class VNPayService {
  static const String baseUrl = 'http://localhost/EcommerceClothingApp/API/vnpay_php';
  
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
        Uri.parse('$baseUrl/create_vnpay_payment.php'),
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
        Uri.parse('$baseUrl/check_payment_status.php'),
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
}
```

### 3. Sử dụng trong Flutter Widget
```dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentScreen extends StatefulWidget {
  final int orderId;
  final double amount;
  final int userId;

  const PaymentScreen({
    Key? key,
    required this.orderId,
    required this.amount,
    required this.userId,
  }) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool isLoading = true;
  String? paymentUrl;
  String? error;

  @override
  void initState() {
    super.initState();
    _createPayment();
  }

  Future<void> _createPayment() async {
    try {
      final result = await VNPayService.createPayment(
        orderId: widget.orderId,
        amount: widget.amount,
        userId: widget.userId,
        orderInfo: 'Thanh toán đơn hàng #${widget.orderId}',
      );

      if (result['success']) {
        setState(() {
          paymentUrl = result['data']['payment_url'];
          isLoading = false;
        });
      } else {
        setState(() {
          error = result['message'];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Thanh toán VNPAY')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Lỗi thanh toán')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('Có lỗi xảy ra: $error'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isLoading = true;
                    error = null;
                  });
                  _createPayment();
                },
                child: Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Thanh toán VNPAY'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                isLoading = true;
              });
              _createPayment();
            },
          ),
        ],
      ),
      body: WebViewWidget(
        controller: WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onNavigationRequest: (NavigationRequest request) {
                // Xử lý khi user navigate
                if (request.url.contains('vnpay_return.php')) {
                  // Thanh toán hoàn tất
                  _checkPaymentStatus();
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
            ),
          )
          ..loadRequest(Uri.parse(paymentUrl!)),
      ),
    );
  }

  Future<void> _checkPaymentStatus() async {
    try {
      final result = await VNPayService.checkPaymentStatus(
        orderId: widget.orderId,
        userId: widget.userId,
      );

      if (result['success'] && result['data']['is_paid']) {
        // Thanh toán thành công
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PaymentSuccessScreen(
              orderId: widget.orderId,
              transactionCode: result['data']['transaction_code'],
            ),
          ),
        );
      } else {
        // Thanh toán thất bại
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PaymentFailedScreen(orderId: widget.orderId),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi kiểm tra trạng thái: $e')),
      );
    }
  }
}
```

## Quy trình thanh toán

1. **Tạo đơn hàng** trong Flutter app
2. **Gọi API** `create_vnpay_payment.php` để tạo URL thanh toán
3. **Mở WebView** với URL thanh toán VNPAY
4. **User thanh toán** trên trang VNPAY
5. **VNPAY redirect** về `vnpay_return.php`
6. **VNPAY gọi IPN** `vnpay_ipn.php` để xác nhận
7. **Flutter app kiểm tra** trạng thái qua `check_payment_status.php`
8. **Hiển thị kết quả** cho user

## Lưu ý quan trọng

1. **Cấu hình VNPAY:**
   - Đảm bảo `vnp_TmnCode` và `vnp_HashSecret` đúng
   - Cập nhật `vnp_Returnurl` đúng đường dẫn
   - Test với sandbox trước khi deploy production

2. **Database:**
   - Đảm bảo bảng `payments` có cột `payment_method` với giá trị 'VNPAY'
   - Kiểm tra foreign key constraints

3. **Security:**
   - Validate tất cả input từ Flutter
   - Kiểm tra user_id để đảm bảo user chỉ thanh toán đơn hàng của mình
   - Sử dụng HTTPS trong production

4. **Error Handling:**
   - Xử lý timeout khi gọi API
   - Retry mechanism cho network errors
   - User-friendly error messages

## Testing

1. Tạo đơn hàng test với số tiền nhỏ
2. Test thanh toán thành công và thất bại
3. Kiểm tra database được cập nhật đúng
4. Test notification được gửi cho user
5. Test trạng thái đơn hàng được cập nhật 