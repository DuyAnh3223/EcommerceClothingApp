# 🔧 Khắc phục lỗi VNPAY

## 🚨 Lỗi thường gặp và cách khắc phục

### 1. Lỗi "timer is not defined" và chuyển đến trang Error.html

**Nguyên nhân:**
- URL return không đúng hoặc không thể truy cập
- Lỗi trong file vnpay_return.php
- Vấn đề với chữ ký bảo mật

**Cách khắc phục:**

#### Bước 1: Kiểm tra URL return
```php
// Trong config.php
$vnp_Returnurl = "http://127.0.0.1/EcommerceClothingApp/API/vnpay_php/vnpay_return.php";
```

#### Bước 2: Test URL return
Mở trình duyệt và truy cập:
```
http://127.0.0.1/EcommerceClothingApp/API/test_vnpay_return.php
```

#### Bước 3: Kiểm tra file vnpay_return.php
- Đảm bảo file tồn tại và có quyền đọc
- Kiểm tra lỗi PHP trong error log

### 2. Lỗi chữ ký không hợp lệ

**Nguyên nhân:**
- Secret key không đúng
- Thứ tự sắp xếp tham số sai
- Encoding không đúng

**Cách khắc phục:**
```php
// Kiểm tra secret key
$vnp_HashSecret = "2RHZSCS89LRN5YYJ543D05Z4MCASEAIP";

// Đảm bảo sắp xếp theo key
ksort($inputData);
```

### 3. Lỗi "An error occurred during the processing"

**Nguyên nhân:**
- VNPAY không thể gọi callback URL
- Lỗi trong xử lý callback
- Timeout

**Cách khắc phục:**

#### Bước 1: Kiểm tra kết nối mạng
```bash
ping sandbox.vnpayment.vn
```

#### Bước 2: Kiểm tra firewall
Đảm bảo port 80/443 được mở

#### Bước 3: Test callback URL
```bash
curl -I http://127.0.0.1/EcommerceClothingApp/API/vnpay_php/vnpay_return.php
```

### 4. Lỗi database trong callback

**Nguyên nhân:**
- Kết nối database lỗi
- Query SQL sai
- Quyền database không đủ

**Cách khắc phục:**
```php
// Thêm error handling
try {
    $pdo = getDBConnection();
    if ($pdo) {
        // Xử lý database
    } else {
        error_log("Cannot connect to database");
    }
} catch (Exception $e) {
    error_log("Database error: " . $e->getMessage());
}
```

## 🧪 Testing Checklist

### Trước khi test thanh toán:
- [ ] Apache server đang chạy
- [ ] MySQL server đang chạy
- [ ] Database connection OK
- [ ] URL return accessible
- [ ] Config VNPAY đúng

### Test thanh toán:
- [ ] Tạo đơn hàng thành công
- [ ] URL thanh toán VNPAY được tạo
- [ ] Mở trang thanh toán VNPAY
- [ ] Nhập thông tin thẻ test
- [ ] Thanh toán thành công
- [ ] Callback về đúng URL
- [ ] Database được cập nhật
- [ ] Notification được tạo

## 🔍 Debug Tools

### 1. Log file
Kiểm tra error log của Apache:
```bash
tail -f /xampp/apache/logs/error.log
```

### 2. Test URL
```bash
# Test return URL
curl http://127.0.0.1/EcommerceClothingApp/API/test_vnpay_return.php

# Test config
curl http://127.0.0.1/EcommerceClothingApp/API/vnpay_php/config.php
```

### 3. Database check
```sql
-- Kiểm tra đơn hàng
SELECT * FROM orders WHERE payment_method = 'VNPAY' ORDER BY id DESC LIMIT 5;

-- Kiểm tra thanh toán
SELECT * FROM payments WHERE payment_method = 'VNPAY' ORDER BY id DESC LIMIT 5;

-- Kiểm tra notification
SELECT * FROM notifications WHERE type = 'order_status' ORDER BY id DESC LIMIT 5;
```

## 🛠️ Cấu hình Production

### 1. Thay đổi URL
```php
// Sandbox -> Production
$vnp_Url = "https://pay.vnpay.vn/vpcpay.html";
$vnp_apiUrl = "https://pay.vnpay.vn/merchant_webapi/merchant.html";
```

### 2. Cập nhật credentials
```php
$vnp_TmnCode = "YOUR_PRODUCTION_TMN_CODE";
$vnp_HashSecret = "YOUR_PRODUCTION_SECRET_KEY";
```

### 3. HTTPS
```php
$vnp_Returnurl = "https://yourdomain.com/API/vnpay_php/vnpay_return.php";
```

## 📞 Hỗ trợ

### VNPAY Support
- **Hotline:** 1900 55 55 77
- **Email:** hotrovnpay@vnpay.vn
- **Website:** https://sandbox.vnpayment.vn/

### Local Debug
1. Kiểm tra error log
2. Test URL accessibility
3. Verify database connection
4. Check VNPAY configuration

## 🎯 Best Practices

1. **Luôn test trong sandbox trước**
2. **Sử dụng HTTPS cho production**
3. **Log đầy đủ thông tin lỗi**
4. **Validate input từ VNPAY**
5. **Handle timeout và retry**
6. **Backup database trước khi test**

## 📋 Checklist khắc phục lỗi

- [ ] Kiểm tra Apache/MySQL đang chạy
- [ ] Verify URL return accessible
- [ ] Check VNPAY config
- [ ] Test database connection
- [ ] Review error logs
- [ ] Validate signature
- [ ] Test with sandbox credentials
- [ ] Check network connectivity 