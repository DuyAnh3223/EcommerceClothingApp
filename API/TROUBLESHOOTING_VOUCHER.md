# 🔧 Khắc phục lỗi Voucher API

## 🚨 Lỗi thường gặp

### 1. Lỗi "Unexpected token '<'" 
**Nguyên nhân:** API trả về HTML error thay vì JSON
**Giải pháp:**
- Kiểm tra file `config/db_connect.php` có tồn tại không
- Kiểm tra kết nối database
- Kiểm tra quyền truy cập file

### 2. Lỗi "Database connection failed"
**Nguyên nhân:** Không kết nối được database
**Giải pháp:**
```bash
# Kiểm tra MySQL đang chạy
# Windows: Services > MySQL
# Linux: sudo systemctl status mysql

# Kiểm tra thông tin kết nối trong config/db_connect.php
$host = "127.0.0.1";
$username = "root";
$password = "";
$database = "clothing_appstore";
```

### 3. Lỗi "Table vouchers doesn't exist"
**Nguyên nhân:** Chưa tạo bảng hoặc chưa cập nhật cơ sở dữ liệu
**Giải pháp:**
```sql
-- Chạy SQL để thêm cột mới
ALTER TABLE vouchers 
ADD COLUMN min_quantity INT DEFAULT 1 COMMENT 'Số lượng sản phẩm tối thiểu để áp dụng',
ADD COLUMN min_total_amount DECIMAL(15,2) DEFAULT 0 COMMENT 'Tổng tiền tối thiểu để áp dụng';

-- Cập nhật dữ liệu
UPDATE vouchers SET min_quantity = 1, min_total_amount = 60000 WHERE voucher_code = 'GIAM20K';
UPDATE vouchers SET min_quantity = 3, min_total_amount = 200000 WHERE voucher_code = 'GIAM30K';
```

## 🧪 Cách test và debug

### 1. Test kết nối database
```bash
# Truy cập: http://localhost/EcommerceClothingApp/API/debug_voucher.php
```

### 2. Test API trực tiếp
```bash
# Sử dụng curl
curl -X POST http://localhost/EcommerceClothingApp/API/vouchers/get_available_vouchers.php \
  -H "Content-Type: application/json" \
  -d '{"user_id": 4, "cart_total": 65000, "cart_quantity": 1}'
```

### 3. Test qua giao diện
```bash
# Truy cập: http://localhost/EcommerceClothingApp/API/test_voucher_conditions.html
```

## 🔍 Debug từng bước

### Bước 1: Kiểm tra cấu trúc thư mục
```
API/
├── config/
│   └── db_connect.php ✅
├── utils/
│   └── response.php ✅
├── vouchers/
│   └── get_available_vouchers.php ✅
├── cart/
│   └── get_cart_summary.php ✅
└── test_voucher_conditions.html ✅
```

### Bước 2: Kiểm tra database
```sql
-- Kiểm tra bảng vouchers
DESCRIBE vouchers;

-- Kiểm tra dữ liệu
SELECT * FROM vouchers WHERE status = 'active';

-- Kiểm tra cột mới
SELECT voucher_code, min_quantity, min_total_amount FROM vouchers;
```

### Bước 3: Kiểm tra PHP errors
```php
// Thêm vào đầu file PHP
error_reporting(E_ALL);
ini_set('display_errors', 1);
```

### Bước 4: Test từng API riêng biệt
```bash
# Test API cart summary
curl "http://localhost/EcommerceClothingApp/API/cart/get_cart_summary.php?user_id=4"

# Test API voucher
curl -X POST http://localhost/EcommerceClothingApp/API/vouchers/get_available_vouchers.php \
  -H "Content-Type: application/json" \
  -d '{"user_id": 4, "cart_total": 65000, "cart_quantity": 1}'
```

## 🛠️ Sửa lỗi cụ thể

### Lỗi mysqli vs PDO
**Vấn đề:** File sử dụng PDO nhưng db_connect.php dùng mysqli
**Giải pháp:** Đã sửa trong file `get_available_vouchers.php`

### Lỗi CORS
**Vấn đề:** Browser chặn request
**Giải pháp:** Đã thêm headers trong file PHP
```php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
```

### Lỗi JSON parsing
**Vấn đề:** Response không phải JSON hợp lệ
**Giải pháp:** 
- Kiểm tra PHP errors
- Đảm bảo chỉ có JSON output
- Không có whitespace trước `<?php`

## 📋 Checklist khắc phục

- [ ] MySQL đang chạy
- [ ] Database `clothing_appstore` tồn tại
- [ ] Bảng `vouchers` có cột `min_quantity` và `min_total_amount`
- [ ] File `config/db_connect.php` có thông tin đúng
- [ ] File `utils/response.php` tồn tại
- [ ] Không có PHP errors
- [ ] API trả về JSON hợp lệ
- [ ] CORS headers đúng
- [ ] Test với user_id = 4 (có trong database)

## 🆘 Nếu vẫn lỗi

1. **Kiểm tra log PHP:**
   - Windows: `xampp/apache/logs/error.log`
   - Linux: `/var/log/apache2/error.log`

2. **Kiểm tra log browser:**
   - F12 > Console > xem errors

3. **Test với Postman:**
   - Import request vào Postman
   - Kiểm tra response headers và body

4. **Tạo file test đơn giản:**
```php
<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "PHP is working\n";
echo "Testing database connection...\n";

require_once 'config/db_connect.php';
echo "Database connected\n";

$sql = "SELECT COUNT(*) as count FROM vouchers";
$result = $conn->query($sql);
$row = $result->fetch_assoc();
echo "Vouchers count: " . $row['count'] . "\n";
?>
```

## 📞 Liên hệ hỗ trợ

Nếu vẫn gặp vấn đề, hãy cung cấp:
1. Error message đầy đủ
2. Response từ debug_voucher.php
3. Log PHP errors
4. Screenshot console browser 