# Hệ thống Mã Giao dịch (Transaction Code System)

## Tổng quan

Hệ thống mã giao dịch tự động tạo mã giao dịch duy nhất cho mỗi thanh toán thành công, giúp theo dõi và quản lý giao dịch một cách hiệu quả.

## Các phương thức thanh toán được hỗ trợ

| Phương thức | Prefix | Ví dụ |
|-------------|--------|-------|
| COD | COD | COD20250104123456789012345678 |
| VNPAY | VNPAY | VNPAY20250104123456789012345678 |
| Momo | MOMO | MOMO20250104123456789012345678 |
| Bank | BANK | BANK20250104123456789012345678 |
| BACoin | BACOIN | BACOIN20250104123456789012345678 |
| Khác | TXN | TXN20250104123456789012345678 |

## Cấu trúc mã giao dịch

```
[PREFIX][TIMESTAMP][RANDOM_NUMBERS]
```

- **PREFIX**: 3-6 ký tự tùy theo phương thức thanh toán
- **TIMESTAMP**: 14 ký tự (YYYYMMDDHHMMSS)
- **RANDOM_NUMBERS**: 8 số ngẫu nhiên

Tổng cộng: 25-28 ký tự

## Cách hoạt động

### 1. Thanh toán COD
- Mã giao dịch được tạo khi admin cập nhật trạng thái đơn hàng thành `confirmed`, `shipping`, hoặc `delivered`
- File: `API/orders/update_order.php`

### 2. Thanh toán VNPAY
- Mã giao dịch được tạo từ VNPAY và lưu vào database khi thanh toán thành công
- File: `API/vnpay_php/vnpay_return.php`

### 3. Thanh toán BACoin
- Mã giao dịch được tạo ngay khi thanh toán thành công (khi đặt hàng)
- **Trạng thái đơn hàng được cập nhật thành `confirmed` ngay lập tức**
- Files: 
  - `API/orders/place_order_multi.php`
  - `API/orders/place_order_with_combinations.php`

## Các file liên quan

### Core Files
- `API/orders/update_order.php` - Tạo mã giao dịch cho COD và các phương thức khác
- `API/orders/place_order_multi.php` - Tạo mã giao dịch cho BACoin
- `API/orders/place_order_with_combinations.php` - Tạo mã giao dịch cho BACoin (combo)

### Test Files
- `API/tests/test_transaction_code.php` - Test tạo mã giao dịch cho tất cả phương thức
- `API/tests/test_bacoin_transaction_code.php` - Test riêng cho BACoin
- `API/tests/update_bacoin_transaction_codes.php` - Cập nhật mã giao dịch cho BACoin cũ
- `API/tests/test_bacoin_order_status.php` - Test trạng thái đơn hàng BACoin
- `API/tests/update_bacoin_order_status.php` - Cập nhật trạng thái đơn hàng BACoin cũ

## Hàm generateTransactionCode()

```php
function generateTransactionCode($paymentMethod) {
    $prefix = '';
    switch ($paymentMethod) {
        case 'Momo':
            $prefix = 'MOMO';
            break;
        case 'VNPAY':
            $prefix = 'VNPAY';
            break;
        case 'Bank':
            $prefix = 'BANK';
            break;
        case 'COD':
            $prefix = 'COD';
            break;
        case 'BACoin':
            $prefix = 'BACOIN';
            break;
        default:
            $prefix = 'TXN';
    }
    
    // Tạo 8 số ngẫu nhiên
    $randomNumbers = str_pad(mt_rand(1, 99999999), 8, '0', STR_PAD_LEFT);
    
    // Thêm timestamp để đảm bảo unique
    $timestamp = date('YmdHis');
    
    return $prefix . $timestamp . $randomNumbers;
}
```

## Database Schema

Bảng `payments` có các trường:
- `transaction_code` VARCHAR(100) - Mã giao dịch
- `payment_method` ENUM - Phương thức thanh toán
- `status` ENUM - Trạng thái thanh toán
- `paid_at` DATETIME - Thời gian thanh toán

## Cách test

### 1. Test tạo mã giao dịch
```
GET /API/tests/test_transaction_code.php
```

### 2. Test riêng cho BACoin
```
GET /API/tests/test_bacoin_transaction_code.php
```

### 3. Cập nhật mã giao dịch cho BACoin cũ
```
GET /API/tests/update_bacoin_transaction_codes.php
```

### 4. Test trạng thái đơn hàng BACoin
```
GET /API/tests/test_bacoin_order_status.php
```

### 5. Cập nhật trạng thái đơn hàng BACoin cũ
```
GET /API/tests/update_bacoin_order_status.php
```

## Lưu ý quan trọng

1. **Tính duy nhất**: Mã giao dịch được đảm bảo duy nhất nhờ timestamp và số ngẫu nhiên
2. **BACoin**: 
   - Mã giao dịch được tạo ngay khi thanh toán thành công
   - **Trạng thái đơn hàng tự động chuyển thành `confirmed`**
   - Không cần chờ admin xác nhận
3. **COD**: Mã giao dịch chỉ được tạo khi admin cập nhật trạng thái đơn hàng
4. **VNPAY**: Mã giao dịch được tạo từ hệ thống VNPAY và lưu vào database

## Troubleshooting

### Vấn đề: BACoin không có mã giao dịch
**Giải pháp**: 
1. Chạy `update_bacoin_transaction_codes.php` để cập nhật các giao dịch cũ
2. Kiểm tra logic trong `place_order_multi.php` và `place_order_with_combinations.php`

### Vấn đề: Mã giao dịch trùng lặp
**Giải pháp**: 
1. Kiểm tra timestamp và random numbers
2. Đảm bảo sử dụng `mt_rand()` thay vì `rand()`

### Vấn đề: Mã giao dịch không đúng format
**Giải pháp**: 
1. Kiểm tra hàm `generateTransactionCode()`
2. Đảm bảo prefix được định nghĩa đúng cho tất cả phương thức thanh toán 