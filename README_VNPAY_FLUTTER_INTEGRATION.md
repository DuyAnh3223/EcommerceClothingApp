# 🚀 Hướng dẫn tích hợp VNPAY với Flutter App

## 📋 Tổng quan

Hệ thống đã được tích hợp hoàn chỉnh VNPAY payment gateway cho Flutter app. Khi người dùng chọn phương thức thanh toán VNPAY, hệ thống sẽ:

1. Tạo đơn hàng trong database
2. Tạo URL thanh toán VNPAY
3. Hiển thị dialog thanh toán
4. Mở trang thanh toán VNPAY sandbox
5. Xử lý callback và cập nhật trạng thái thanh toán

## 🔧 Cấu hình

### 1. Thông tin VNPAY Sandbox
- **Terminal ID:** `F283H148`
- **Secret Key:** `2RHZSCS89LRN5YYJ543D05Z4MCASEAIP`
- **Payment URL:** `https://sandbox.vnpayment.vn/paymentv2/vpcpay.html`

### 2. Thông tin thẻ test (Chỉ dành cho developer)
> ⚠️ **Lưu ý bảo mật:** Thông tin thẻ test chỉ được sử dụng trong môi trường development và không được hiển thị cho khách hàng.

Thông tin thẻ test được lưu trong file `API/vnpay_php/taikhoantest.txt` và chỉ dành cho mục đích testing.

## 📁 Cấu trúc file

### Backend (PHP)
```
API/
├── vnpay_php/
│   ├── config.php                 # Cấu hình VNPAY
│   ├── create_vnpay_payment.php   # API tạo thanh toán
│   ├── check_payment_status.php   # API kiểm tra trạng thái
│   ├── vnpay_return.php          # Xử lý callback
│   ├── vnpay_ipn.php             # Xử lý IPN
│   └── taikhoantest.txt          # Thông tin thẻ test (private)
├── orders/
│   ├── place_order.php           # Đặt hàng đơn sản phẩm
│   └── place_order_multi.php     # Đặt hàng nhiều sản phẩm
└── config/
    └── db_connect.php            # Kết nối database
```

### Frontend (Flutter)
```
userfe/lib/
├── services/
│   ├── vnpay_service.dart        # Service VNPAY
│   └── auth_service.dart         # Service xác thực
└── screens/home/
    ├── home_screen.dart          # Màn hình chính
    └── cart_screen.dart          # Màn hình giỏ hàng
```

## 🎯 Luồng thanh toán

### 1. Người dùng chọn VNPAY
```dart
// Trong dropdown payment method
DropdownMenuItem(value: 'VNPAY', child: Text('VNPAY'))
```

### 2. Đặt hàng và tạo URL thanh toán
```dart
final result = await AuthService.placeOrder(
  userId: userId,
  productId: productId,
  variantId: variantId,
  quantity: quantity,
  addressId: addressId,
  paymentMethod: 'VNPAY',
);

if (result['requires_payment'] == true) {
  _showVNPayPaymentDialog(result['payment_url'], result['order_id']);
}
```

### 3. Hiển thị dialog thanh toán
```dart
void _showVNPayPaymentDialog(String paymentUrl, int orderId) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Thanh toán VNPAY'),
      content: Column(
        children: [
          Text('Đơn hàng đã được tạo thành công!'),
          Text('Mã đơn hàng: #$orderId'),
          Text('Bạn sẽ được chuyển đến trang thanh toán VNPAY để hoàn tất giao dịch.'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Thanh toán sau'),
        ),
        ElevatedButton(
          onPressed: () async {
            await VNPayService.openPaymentUrl(paymentUrl);
            Navigator.of(context).pop();
          },
          child: Text('💳 Thanh toán ngay'),
        ),
      ],
    ),
  );
}
```

### 4. Mở trang thanh toán
```dart
class VNPayService {
  static Future<void> openPaymentUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch payment URL');
    }
  }
}
```

## 🧪 Testing

### 1. Test file HTML
Mở file `API/test_vnpay_integration.html` trong trình duyệt để test các API:

- **Test 1:** Đặt hàng đơn sản phẩm với VNPAY
- **Test 2:** Đặt hàng nhiều sản phẩm với VNPAY
- **Test 3:** Kiểm tra trạng thái thanh toán
- **Test 4:** Mở URL thanh toán

### 2. Test trong Flutter App
1. Chạy Flutter app: `flutter run`
2. Đăng nhập với tài khoản user
3. Chọn sản phẩm và thêm vào giỏ hàng
4. Chọn phương thức thanh toán VNPAY
5. Nhấn "Đặt hàng"
6. Trong dialog thanh toán, nhấn "Thanh toán ngay"
7. Sử dụng thông tin thẻ test từ file `taikhoantest.txt` để hoàn tất thanh toán

## 📱 Cài đặt dependencies

### Flutter dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  url_launcher: ^6.2.1
  cached_network_image: ^3.3.0
  shared_preferences: ^2.2.2
```

### Cài đặt
```bash
cd userfe
flutter pub get
```

## 🔄 API Endpoints

### 1. Đặt hàng đơn sản phẩm
```
POST /API/orders/place_order.php
Content-Type: application/json

{
  "user_id": 4,
  "product_id": 3,
  "variant_id": 4,
  "quantity": 1,
  "address_id": 3,
  "payment_method": "VNPAY"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Đặt hàng thành công! Vui lòng thanh toán qua VNPAY.",
  "order_id": 25,
  "payment_method": "VNPAY",
  "payment_url": "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html?...",
  "requires_payment": true
}
```

### 2. Đặt hàng nhiều sản phẩm
```
POST /API/orders/place_order_multi.php
Content-Type: application/json

{
  "user_id": 4,
  "address_id": 3,
  "payment_method": "VNPAY",
  "items": [
    {
      "product_id": 3,
      "variant_id": 4,
      "quantity": 1
    },
    {
      "product_id": 4,
      "variant_id": 6,
      "quantity": 2
    }
  ]
}
```

### 3. Kiểm tra trạng thái thanh toán
```
POST /API/vnpay_php/check_payment_status.php
Content-Type: application/json

{
  "order_id": 25,
  "user_id": 4
}
```

**Response:**
```json
{
  "success": true,
  "order_id": 25,
  "payment_status": "paid",
  "order_status": "confirmed",
  "amount": 500000,
  "transaction_code": "VNPAY20250101123456789"
}
```

## 🚨 Xử lý lỗi

### 1. Lỗi kết nối
```dart
try {
  await VNPayService.openPaymentUrl(paymentUrl);
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Lỗi mở trang thanh toán: $e'),
      backgroundColor: Colors.red,
    ),
  );
}
```

### 2. Lỗi API
```dart
if (result['success'] == true) {
  // Xử lý thành công
} else {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(result['message'] ?? 'Có lỗi xảy ra'),
      backgroundColor: Colors.red,
    ),
  );
}
```

## 📊 Database Schema

### Bảng payments
```sql
CREATE TABLE `payments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `order_id` int(11) NOT NULL,
  `payment_method` enum('COD','Bank','Momo','VNPAY','Other') NOT NULL,
  `amount` decimal(15,2) NOT NULL,
  `status` enum('pending','paid','failed','refunded') DEFAULT 'pending',
  `transaction_code` varchar(100) DEFAULT NULL,
  `paid_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `order_id` (`order_id`)
);
```

### Bảng orders
```sql
CREATE TABLE `orders` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `address_id` int(11) NOT NULL,
  `order_date` datetime DEFAULT current_timestamp(),
  `total_amount` decimal(15,2) NOT NULL,
  `status` enum('pending','confirmed','shipping','delivered','cancelled') DEFAULT 'pending',
  PRIMARY KEY (`id`)
);
```

## 🔐 Bảo mật

### 1. Thông tin nhạy cảm
- **Secret Key:** Được lưu trong `config.php` và không được commit lên git
- **Thông tin thẻ test:** Chỉ lưu trong file private `taikhoantest.txt`
- **Không hiển thị thông tin thẻ test trong giao diện khách hàng**

### 2. Bảo mật hệ thống
- **HTTPS:** Sử dụng HTTPS cho production
- **Validation:** Validate tất cả input từ client
- **IPN:** Xử lý IPN để đảm bảo tính toàn vẹn của giao dịch
- **Access Control:** Kiểm tra quyền truy cập API

### 3. Bảo vệ dữ liệu khách hàng
- Không lưu thông tin thẻ thanh toán
- Mã hóa dữ liệu nhạy cảm
- Tuân thủ quy định bảo mật dữ liệu

## 🚀 Deployment

### 1. Production
- Thay đổi URL từ sandbox sang production
- Cập nhật Terminal ID và Secret Key
- Cấu hình IPN URL
- Bật HTTPS
- Xóa tất cả thông tin test khỏi giao diện

### 2. Testing
- Sử dụng sandbox environment
- Test với thẻ test được cung cấp (chỉ trong development)
- Kiểm tra callback và IPN
- Đảm bảo không có thông tin test trong production

## 📞 Hỗ trợ

Nếu gặp vấn đề, hãy kiểm tra:

1. **Logs:** Kiểm tra error logs của server
2. **Network:** Đảm bảo kết nối internet ổn định
3. **Config:** Kiểm tra cấu hình VNPAY
4. **Database:** Kiểm tra kết nối database
5. **Security:** Đảm bảo không có thông tin nhạy cảm bị lộ

## 🎉 Kết luận

Hệ thống đã được tích hợp hoàn chỉnh VNPAY payment gateway với các biện pháp bảo mật phù hợp. Người dùng có thể:

- Chọn VNPAY làm phương thức thanh toán
- Được chuyển đến trang thanh toán VNPAY sandbox
- Hoàn tất thanh toán an toàn
- Nhận thông báo về trạng thái thanh toán
- Xem lịch sử giao dịch trong app

**Lưu ý:** Thông tin thẻ test chỉ dành cho mục đích development và không được hiển thị cho khách hàng cuối.

Tất cả đã sẵn sàng để test và deploy! 🚀 