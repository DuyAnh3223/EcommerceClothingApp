# Hướng dẫn khắc phục lỗi VNPAY

## Cấu hình VNPAY hiện tại

**Terminal ID:** F283H148  
**Secret Key:** 2RHZSCS89LRN5YYJ543D05Z4MCASEAIP  
**Environment:** Sandbox (Test)  
**URL:** https://sandbox.vnpayment.vn/paymentv2/vpcpay.html

## Lỗi thường gặp

### 1. Lỗi JSON Parsing: "Unexpected token '<'"

**Nguyên nhân:** API trả về HTML thay vì JSON do lỗi PHP hoặc thiếu file config.

**Cách khắc phục:**

1. **Kiểm tra file config.php:**
   - Đảm bảo file `API/vnpay_php/config.php` tồn tại
   - Kiểm tra cấu hình database trong file config.php

2. **Test API connection:**
   - Mở file `API/test_vnpay_connection.html` trong trình duyệt
   - Click "Test Connection" để kiểm tra kết nối database
   - Click "Test Create Payment" để kiểm tra API tạo thanh toán

3. **Kiểm tra log lỗi:**
   - Xem log lỗi PHP trong XAMPP
   - Kiểm tra console của trình duyệt để xem response

### 2. Lỗi VNPAY Code=15: "Transaction time expired"

**Nguyên nhân:** 
- Thời gian tạo giao dịch không chính xác
- URL thanh toán đã hết hạn (quá 15 phút)
- Sai format thời gian hoặc timezone

**Cách khắc phục:**

1. **Kiểm tra timezone:**
   ```php
   date_default_timezone_set('Asia/Ho_Chi_Minh');
   ```

2. **Kiểm tra format thời gian:**
   ```php
   $vnp_CreateDate = date('YmdHis'); // Format: 20250629130456
   $vnp_ExpireDate = date('YmdHis', strtotime('+15 minutes'));
   ```

3. **Test URL generator:**
   - Mở file `API/test_vnpay_url_generator.html`
   - Generate payment URL mới
   - Test URL ngay lập tức (không để quá 15 phút)

4. **Kiểm tra thông tin VNPAY:**
   - Đảm bảo `$vnp_TmnCode` và `$vnp_HashSecret` đúng
   - Kiểm tra URL VNPAY đúng environment

### 3. Lỗi Database Connection

**Nguyên nhân:** Không thể kết nối database hoặc sai thông tin kết nối.

**Cách khắc phục:**

1. **Kiểm tra thông tin database trong `config.php`:**
   ```php
   define('DB_HOST', '127.0.0.1');
   define('DB_NAME', 'clothing_appstore');
   define('DB_USER', 'root');
   define('DB_PASS', '');
   ```

2. **Đảm bảo database tồn tại:**
   - Import file `API/clothing_appstore.sql` vào phpMyAdmin
   - Kiểm tra database `clothing_appstore` có tồn tại

3. **Kiểm tra XAMPP:**
   - Đảm bảo Apache và MySQL đang chạy
   - Kiểm tra port 80 và 3306 không bị conflict

### 4. Lỗi VNPAY Configuration

**Nguyên nhân:** Sai thông tin cấu hình VNPAY.

**Cách khắc phục:**

1. **Cập nhật thông tin VNPAY trong `config.php`:**
   ```php
   // Thông tin VNPAY thực tế
   $vnp_TmnCode = "F283H148";
   $vnp_HashSecret = "2RHZSCS89LRN5YYJ543D05Z4MCASEAIP";
   $vnp_Url = "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html";
   ```

2. **Kiểm tra URL:**
   - Test environment: `https://sandbox.vnpayment.vn/paymentv2/vpcpay.html`
   - Production: `https://pay.vnpay.vn/vpcpay.html`

### 5. Lỗi CORS

**Nguyên nhân:** Trình duyệt chặn request do CORS policy.

**Cách khắc phục:**

1. **Đảm bảo headers CORS trong PHP:**
   ```php
   header('Access-Control-Allow-Origin: *');
   header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
   header('Access-Control-Allow-Headers: Content-Type, Authorization');
   ```

2. **Kiểm tra URL trong Flutter:**
   - Đảm bảo URL API đúng: `http://127.0.0.1/EcommerceClothingApp/API`

## Các bước test

### Bước 1: Test Configuration
1. Mở `http://localhost/EcommerceClothingApp/API/test_vnpay_url_generator.html`
2. Click "Test VNPAY Config"
3. Kiểm tra thông tin cấu hình

### Bước 2: Generate và Test Payment URL
1. Trong cùng trang test
2. Điền thông tin test (Order ID: 1, Amount: 100000, User ID: 4)
3. Click "Generate Payment URL"
4. Click "Test Payment URL" ngay lập tức

### Bước 3: Test Flutter App
1. Chạy Flutter app
2. Thử thanh toán VNPAY
3. Kiểm tra console log để xem lỗi

## Debug trong Flutter

Thêm debug logging trong `VNPayService`:

```dart
print('VNPAY: Creating payment for order #$orderId, amount: $amount');
print('VNPAY: Response status: ${response.statusCode}');
print('VNPAY: Response body: ${response.body}');
```

## Cấu trúc file quan trọng

```
API/
├── vnpay_php/
│   ├── config.php              # Cấu hình VNPAY và database
│   ├── create_vnpay_payment.php # API tạo thanh toán
│   ├── vnpay_return_api.php    # API xử lý kết quả thanh toán
│   └── test_vnpay_api.php      # API test kết nối
├── config/
│   ├── config.php              # Cấu hình database chung
│   └── db_connect.php          # Kết nối database
├── test_vnpay_connection.html  # File test cơ bản
└── test_vnpay_url_generator.html # File test URL generator
```

## Lưu ý quan trọng

1. **Environment:** Đảm bảo sử dụng đúng environment (test/production)
2. **Database:** Import đầy đủ schema database
3. **Permissions:** Đảm bảo file PHP có quyền đọc/ghi
4. **Network:** Kiểm tra kết nối mạng và firewall
5. **Logs:** Luôn kiểm tra log lỗi để debug
6. **Time:** URL thanh toán chỉ có hiệu lực trong 15 phút
7. **Timezone:** Đảm bảo timezone đúng (Asia/Ho_Chi_Minh)

## Các mã lỗi VNPAY thường gặp

- **Code=00:** Giao dịch thành công
- **Code=15:** Thời gian giao dịch hết hạn
- **Code=24:** Giao dịch không thành công
- **Code=51:** Tài khoản không đủ số dư
- **Code=65:** Tài khoản bị khóa

## Liên hệ hỗ trợ

Nếu vẫn gặp lỗi, vui lòng:
1. Chụp màn hình lỗi
2. Copy log lỗi từ console
3. Mô tả các bước đã thực hiện
4. Gửi thông tin để được hỗ trợ 