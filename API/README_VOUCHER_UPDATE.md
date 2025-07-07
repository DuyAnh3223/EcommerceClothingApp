# 🎫 Hướng dẫn cập nhật Voucher với điều kiện

## 📋 Các bước thực hiện

### Bước 1: Cập nhật cơ sở dữ liệu

**Cách 1: Sử dụng phpMyAdmin**
1. Mở phpMyAdmin
2. Chọn database `clothing_appstore`
3. Chạy SQL query sau:

```sql
-- Thêm cột điều kiện cho bảng vouchers
ALTER TABLE vouchers 
ADD COLUMN min_quantity INT DEFAULT 1 COMMENT 'Số lượng sản phẩm tối thiểu để áp dụng',
ADD COLUMN min_total_amount DECIMAL(15,2) DEFAULT 0 COMMENT 'Tổng tiền tối thiểu để áp dụng';

-- Cập nhật dữ liệu ví dụ cho các voucher
UPDATE vouchers SET min_quantity = 1, min_total_amount = 60000 WHERE voucher_code = 'GIAM20K';
UPDATE vouchers SET min_quantity = 3, min_total_amount = 200000 WHERE voucher_code = 'GIAM30K';
UPDATE vouchers SET min_quantity = 1, min_total_amount = 0 WHERE voucher_code = 'WELCOME2024';
UPDATE vouchers SET min_quantity = 1, min_total_amount = 0 WHERE voucher_code = 'SUMMER50K';
UPDATE vouchers SET min_quantity = 1, min_total_amount = 0 WHERE voucher_code = 'NEWYEAR100K';
UPDATE vouchers SET min_quantity = 1, min_total_amount = 0 WHERE voucher_code = 'FLASH25K';
UPDATE vouchers SET min_quantity = 1, min_total_amount = 0 WHERE voucher_code = 'VIP200K';
UPDATE vouchers SET min_quantity = 1, min_total_amount = 0 WHERE voucher_code = 'EMMUONQUAMON';
UPDATE vouchers SET min_quantity = 1, min_total_amount = 0 WHERE voucher_code = 'TEST2025';
UPDATE vouchers SET min_quantity = 1, min_total_amount = 0 WHERE voucher_code = 'TEST2';
UPDATE vouchers SET min_quantity = 1, min_total_amount = 0 WHERE voucher_code = 'GIAM40K';
```

**Cách 2: Sử dụng file PHP**
1. Mở terminal/command prompt
2. Di chuyển đến thư mục dự án
3. Chạy lệnh:
```bash
php API/update_voucher_database.php
```

### Bước 2: Test API

1. Mở trình duyệt
2. Truy cập: `http://localhost/EcommerceClothingApp/API/test_voucher_conditions.html`
3. Test các trường hợp khác nhau

### Bước 3: Kiểm tra API

**Test API lấy voucher:**
```bash
curl -X POST http://localhost/EcommerceClothingApp/API/vouchers/get_available_vouchers.php \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 4,
    "cart_total": 65000,
    "cart_quantity": 1
  }'
```

**Test API lấy thông tin giỏ hàng:**
```bash
curl "http://localhost/EcommerceClothingApp/API/cart/get_cart_summary.php?user_id=4"
```

## 🧪 Test Cases

### Test Case 1: 1 sản phẩm, 65.000đ
- **Input:** cart_quantity = 1, cart_total = 65000
- **Expected:** ✅ Hiển thị voucher "GIAM20K"
- **Reason:** Đủ điều kiện (≥1 sản phẩm, ≥60K)

### Test Case 2: 3 sản phẩm, 210.000đ
- **Input:** cart_quantity = 3, cart_total = 210000
- **Expected:** ✅ Hiển thị cả "GIAM20K" và "GIAM30K"
- **Reason:** Đủ điều kiện cho cả hai voucher

### Test Case 3: 2 sản phẩm, 150.000đ
- **Input:** cart_quantity = 2, cart_total = 150000
- **Expected:** ✅ "GIAM20K", ❌ "GIAM30K" (mờ)
- **Reason:** Đủ tiền nhưng thiếu số lượng cho GIAM30K

### Test Case 4: 1 sản phẩm, 30.000đ
- **Input:** cart_quantity = 1, cart_total = 30000
- **Expected:** ❌ Tất cả voucher đều mờ
- **Reason:** Không đủ tổng tiền cho bất kỳ voucher nào

## 📁 Files đã tạo

1. `API/update_voucher_database.php` - Script cập nhật DB
2. `API/vouchers/get_available_vouchers.php` - API lấy voucher
3. `API/cart/get_cart_summary.php` - API lấy thông tin giỏ hàng
4. `API/test_voucher_conditions.html` - File test giao diện
5. `API/VOUCHER_CONDITIONS_GUIDE.md` - Hướng dẫn chi tiết
6. `API/update_voucher_conditions.sql` - File SQL

## ✅ Kết quả mong đợi

Sau khi hoàn thành, hệ thống sẽ:

1. ✅ Hiển thị voucher có thể sử dụng với border xanh
2. ✅ Hiển thị voucher không đủ điều kiện với border đỏ mờ
3. ✅ Hiển thị thông báo cụ thể về điều kiện chưa đủ
4. ✅ Tự động cập nhật khi thay đổi giỏ hàng
5. ✅ Kiểm tra voucher đã sử dụng và ẩn đi

## 🔧 Troubleshooting

### Lỗi "php not recognized"
- Cài đặt XAMPP hoặc WAMP
- Thêm PHP vào PATH
- Hoặc sử dụng phpMyAdmin để chạy SQL

### Lỗi database connection
- Kiểm tra file `config/db_connect.php`
- Đảm bảo MySQL đang chạy
- Kiểm tra thông tin database

### API trả về lỗi
- Kiểm tra log error trong PHP
- Đảm bảo các file PHP có quyền đọc
- Kiểm tra CORS headers

## 📞 Hỗ trợ

Nếu gặp vấn đề, hãy kiểm tra:
1. Log lỗi trong console browser
2. Log lỗi PHP trong XAMPP/WAMP
3. Kết nối database
4. Quyền truy cập file 