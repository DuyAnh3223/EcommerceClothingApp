# 🎫 Hướng dẫn sử dụng Voucher với điều kiện

## 📋 Tổng quan

Hệ thống voucher đã được cập nhật để hỗ trợ điều kiện về số lượng sản phẩm và tổng tiền thanh toán. Voucher sẽ chỉ hiển thị và cho phép sử dụng khi đủ điều kiện.

## 🗄️ Cập nhật cơ sở dữ liệu

### Bước 1: Thêm cột điều kiện
```sql
ALTER TABLE vouchers 
ADD COLUMN min_quantity INT DEFAULT 1 COMMENT 'Số lượng sản phẩm tối thiểu để áp dụng',
ADD COLUMN min_total_amount DECIMAL(15,2) DEFAULT 0 COMMENT 'Tổng tiền tối thiểu để áp dụng';
```

### Bước 2: Cập nhật dữ liệu ví dụ
```sql
-- Voucher giảm 20K cho đơn ≥ 60K
UPDATE vouchers SET min_quantity = 1, min_total_amount = 60000 WHERE voucher_code = 'GIAM20K';

-- Voucher giảm 30K cho đơn ≥ 200K và số lượng ≥ 3
UPDATE vouchers SET min_quantity = 3, min_total_amount = 200000 WHERE voucher_code = 'GIAM30K';
```

## 🔧 API Endpoints

### 1. Lấy voucher có thể sử dụng
**Endpoint:** `POST /API/vouchers/get_available_vouchers.php`

**Request Body:**
```json
{
    "user_id": 4,
    "cart_total": 65000,
    "cart_quantity": 1
}
```

**Response:**
```json
{
    "success": true,
    "message": "Lấy danh sách voucher thành công",
    "data": {
        "eligible_vouchers": [
            {
                "id": 11,
                "voucher_code": "GIAM20K",
                "discount_amount": 20000,
                "discount_formatted": "20,000đ",
                "min_quantity": 1,
                "min_total_amount": 60000,
                "condition_text": " (Tổng tiền ≥ 60,000đ)",
                "is_available": true,
                "meets_quantity": true,
                "meets_amount": true,
                "already_used": false,
                "status_message": "Có thể sử dụng"
            }
        ],
        "ineligible_vouchers": [
            {
                "id": 12,
                "voucher_code": "GIAM30K",
                "discount_amount": 30000,
                "discount_formatted": "30,000đ",
                "min_quantity": 3,
                "min_total_amount": 200000,
                "condition_text": " (Số lượng ≥ 3 và Tổng tiền ≥ 200,000đ)",
                "is_available": false,
                "meets_quantity": false,
                "meets_amount": false,
                "already_used": false,
                "status_message": "Chưa đủ điều kiện (Số lượng ≥ 3 và Tổng tiền ≥ 200,000đ)"
            }
        ],
        "cart_info": {
            "total_amount": 65000,
            "total_quantity": 1
        }
    }
}
```

### 2. Lấy thông tin giỏ hàng
**Endpoint:** `GET /API/cart/get_cart_summary.php?user_id=4`

**Response:**
```json
{
    "success": true,
    "message": "Lấy thông tin giỏ hàng thành công",
    "data": {
        "cart_items": [...],
        "summary": {
            "total_amount": 65000,
            "total_quantity": 1,
            "total_amount_bacoin": 0,
            "item_count": 1
        }
    }
}
```

## 🧪 Test Cases

### Test Case 1: 1 sản phẩm, 65.000đ
- **Kết quả:** ✅ Hiển thị voucher "GIAM20K" (giảm 20K cho đơn ≥ 60K)
- **Lý do:** Đủ điều kiện số lượng (≥1) và tổng tiền (≥60K)

### Test Case 2: 3 sản phẩm, 210.000đ
- **Kết quả:** ✅ Hiển thị cả "GIAM20K" và "GIAM30K"
- **Lý do:** Đủ điều kiện cho cả hai voucher

### Test Case 3: 2 sản phẩm, 150.000đ
- **Kết quả:** ✅ Hiển thị "GIAM20K", ❌ "GIAM30K" (mờ)
- **Lý do:** Đủ tiền nhưng thiếu số lượng cho GIAM30K

### Test Case 4: 1 sản phẩm, 30.000đ
- **Kết quả:** ❌ Tất cả voucher đều mờ
- **Lý do:** Không đủ tổng tiền cho bất kỳ voucher nào

## 🎨 Hiển thị trên giao diện

### Voucher có thể sử dụng:
- ✅ Border xanh, background xanh nhạt
- Hiển thị: "Có thể sử dụng"
- Cho phép chọn

### Voucher không đủ điều kiện:
- ❌ Border đỏ, background đỏ nhạt, opacity 0.7
- Hiển thị thông báo cụ thể:
  - "Chưa đủ điều kiện (Số lượng ≥ 3 và Tổng tiền ≥ 200,000đ)"
  - "Cần 3 sản phẩm trở lên"
  - "Cần tổng tiền ≥ 200,000đ"
  - "Đã sử dụng voucher này"

## 📱 Cách sử dụng trong Flutter

```dart
// 1. Lấy thông tin giỏ hàng
final cartResponse = await http.get(
  Uri.parse('$baseUrl/cart/get_cart_summary.php?user_id=$userId')
);

// 2. Lấy voucher có thể sử dụng
final voucherResponse = await http.post(
  Uri.parse('$baseUrl/vouchers/get_available_vouchers.php'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'user_id': userId,
    'cart_total': cartSummary['total_amount'],
    'cart_quantity': cartSummary['total_quantity'],
  }),
);

// 3. Hiển thị voucher
final vouchers = jsonDecode(voucherResponse.body)['data'];
final eligibleVouchers = vouchers['eligible_vouchers'];
final ineligibleVouchers = vouchers['ineligible_vouchers'];
```

## 🔄 Cập nhật tự động

Hệ thống sẽ tự động cập nhật danh sách voucher khi:
- Thêm/xóa sản phẩm khỏi giỏ hàng
- Thay đổi số lượng sản phẩm
- Áp dụng voucher khác

## 📝 Lưu ý

1. **Voucher đã sử dụng:** Không hiển thị lại cho cùng user
2. **Voucher hết hạn:** Tự động ẩn khi quá ngày end_date
3. **Voucher hết số lượng:** Tự động ẩn khi quantity = 0
4. **Điều kiện kết hợp:** Cả số lượng VÀ tổng tiền phải đủ
5. **Format tiền:** Hiển thị với dấu phẩy ngăn cách hàng nghìn 