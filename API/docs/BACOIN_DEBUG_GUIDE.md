# Hướng Dẫn Debug Lỗi BACoin Payment

## Lỗi 400 (Bad Request)

### Nguyên nhân có thể:
1. **Thiếu tham số**: `user_id` hoặc `order_id` không được gửi
2. **Tham số không hợp lệ**: `user_id` hoặc `order_id` = 0 hoặc âm
3. **Không tìm thấy đơn hàng**: Đơn hàng không tồn tại hoặc không thuộc về user
4. **Số dư không đủ**: User không có đủ BACoin

### Cách Debug:

#### 1. Kiểm tra log error
```bash
# Xem log PHP error
tail -f /path/to/php/error.log

# Hoặc kiểm tra Apache error log
tail -f /var/log/apache2/error.log
```

#### 2. Chạy test API
```bash
# Chạy file test
php API/vnpay_php_BACoin/test_bacoin_api.php
```

#### 3. Kiểm tra request từ frontend
```javascript
// Kiểm tra request được gửi
console.log('Request data:', {
    user_id: userId,
    order_id: orderId
});

// Kiểm tra response
fetch('/API/vnpay_php_BACoin/bacoin_payment.php', {
    method: 'POST',
    headers: {
        'Content-Type': 'application/json'
    },
    body: JSON.stringify({
        user_id: userId,
        order_id: orderId
    })
})
.then(response => {
    console.log('Response status:', response.status);
    return response.json();
})
.then(data => {
    console.log('Response data:', data);
})
.catch(error => {
    console.error('Error:', error);
});
```

### Các bước kiểm tra:

#### 1. Kiểm tra database
```sql
-- Kiểm tra user có tồn tại
SELECT id, balance FROM users WHERE id = ?;

-- Kiểm tra order có tồn tại
SELECT id, user_id, total_amount FROM orders WHERE id = ?;

-- Kiểm tra bảng bacoin_transactions
DESCRIBE bacoin_transactions;
```

#### 2. Kiểm tra config
```php
// Kiểm tra file config
echo "ADMIN_USER_ID: " . ADMIN_USER_ID . "\n";
echo "AGENCY_PLATFORM_FEE_RATE: " . AGENCY_PLATFORM_FEE_RATE . "\n";
```

#### 3. Test trực tiếp API
```bash
# Test với curl
curl -X POST http://localhost/EcommerceClothingApp/API/vnpay_php_BACoin/bacoin_payment.php \
  -H "Content-Type: application/json" \
  -d '{"user_id": 1, "order_id": 1}'
```

### Các lỗi thường gặp:

#### 1. "Thiếu tham số hoặc tham số không hợp lệ"
- Kiểm tra frontend có gửi đúng `user_id` và `order_id`
- Kiểm tra method request (POST/GET/JSON)

#### 2. "Không tìm thấy đơn hàng hoặc không đúng user"
- Kiểm tra `order_id` có tồn tại trong database
- Kiểm tra `user_id` có đúng với user tạo đơn hàng

#### 3. "Số dư BACoin không đủ"
- Kiểm tra balance của user trong bảng `users`
- Kiểm tra `total_amount` của đơn hàng

#### 4. "Lỗi kết nối database"
- Kiểm tra file `config/db_connect.php`
- Kiểm tra thông tin database

### Debug log được thêm vào API:
- Log tất cả tham số nhận được
- Log quá trình xử lý
- Log lỗi chi tiết

### Cách sửa lỗi:

#### 1. Nếu lỗi tham số:
```javascript
// Đảm bảo gửi đúng format
const requestData = {
    user_id: parseInt(userId),
    order_id: parseInt(orderId)
};
```

#### 2. Nếu lỗi database:
```sql
-- Tạo bảng nếu chưa có
CREATE TABLE IF NOT EXISTS bacoin_transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    type ENUM('spend', 'receive') NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

#### 3. Nếu lỗi config:
```php
// Kiểm tra file config/config.php
define('ADMIN_USER_ID', 1);
define('AGENCY_PLATFORM_FEE_RATE', 20);
``` 