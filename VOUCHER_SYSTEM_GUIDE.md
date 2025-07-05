# Hệ thống Quản lý Voucher - Hướng dẫn sử dụng

## Tổng quan

Hệ thống voucher đã được nâng cấp để hỗ trợ 3 loại voucher khác nhau:

1. **Tất cả sản phẩm** (`all_products`) - Áp dụng cho tất cả sản phẩm
2. **Sản phẩm cụ thể** (`specific_products`) - Chỉ áp dụng cho các sản phẩm được chọn
3. **Theo danh mục** (`category_based`) - Áp dụng cho tất cả sản phẩm trong một danh mục

## Cài đặt Database

### Bước 1: Chạy Migration
```bash
cd API
php run_voucher_migration.php
```

Migration sẽ:
- Tạo bảng `voucher_product_associations` để liên kết voucher với sản phẩm
- Thêm cột `voucher_type` và `category_filter` vào bảng `vouchers`
- Cập nhật dữ liệu hiện có

### Bước 2: Kiểm tra Database
```sql
-- Kiểm tra cấu trúc bảng vouchers
DESCRIBE vouchers;

-- Kiểm tra bảng voucher_product_associations
DESCRIBE voucher_product_associations;
```

## Sử dụng trong Admin Panel

### 1. Truy cập Quản lý Voucher
- Đăng nhập vào admin panel
- Chọn "Quản lý Vouchers" từ sidebar menu

### 2. Tạo Voucher mới
1. Click nút "+" (Floating Action Button)
2. Điền thông tin cơ bản:
   - **Mã Voucher**: Mã duy nhất
   - **Số tiền giảm giá**: Số tiền giảm (VNĐ)
   - **Số lượng**: Số lần có thể sử dụng
   - **Ngày bắt đầu/kết thúc**: Thời gian hiệu lực

3. Chọn **Loại Voucher**:
   - **Tất cả sản phẩm**: Áp dụng cho mọi sản phẩm
   - **Sản phẩm cụ thể**: Chọn từ danh sách sản phẩm
   - **Theo danh mục**: Chọn danh mục sản phẩm

4. Nếu chọn "Sản phẩm cụ thể":
   - Danh sách sản phẩm sẽ hiển thị
   - Tick chọn các sản phẩm muốn áp dụng voucher

5. Nếu chọn "Theo danh mục":
   - Chọn danh mục từ dropdown

### 3. Chỉnh sửa Voucher
- Click icon "Sửa" (biểu tượng bút chì)
- Thay đổi thông tin cần thiết
- Lưu thay đổi

### 4. Xóa Voucher
- Click icon "Xóa" (biểu tượng thùng rác)
- Xác nhận xóa

## API Endpoints

### 1. Lấy danh sách voucher
```
GET /API/vouchers/get_vouchers.php
```

### 2. Tạo voucher mới
```
POST /API/vouchers/add_voucher.php
Content-Type: application/json

{
  "voucher_code": "SUMMER2024",
  "discount_amount": 50000,
  "quantity": 100,
  "start_date": "2024-06-01T00:00:00",
  "end_date": "2024-08-31T23:59:59",
  "voucher_type": "specific_products",
  "associated_product_ids": [1, 2, 3]
}
```

### 3. Validate voucher
```
POST /API/vouchers/validate_voucher.php
Content-Type: application/json

{
  "voucher_code": "SUMMER2024",
  "product_ids": [1, 2, 3, 4]
}
```

Response:
```json
{
  "success": true,
  "message": "Voucher is valid",
  "data": {
    "voucher_id": 1,
    "voucher_code": "SUMMER2024",
    "discount_amount": 50000,
    "total_discount": 150000,
    "applicable_products": [1, 2, 3],
    "remaining_quantity": 95,
    "voucher_type": "specific_products",
    "category_filter": null
  }
}
```

## Tích hợp vào Frontend

### 1. Trong trang sản phẩm
```dart
// Kiểm tra voucher có áp dụng cho sản phẩm không
bool isVoucherApplicable(Voucher voucher, int productId) {
  return voucher.isApplicableForProduct(productId);
}
```

### 2. Trong giỏ hàng
```dart
// Validate voucher cho danh sách sản phẩm
Future<VoucherValidationResult> validateVoucher(String voucherCode, List<int> productIds) async {
  final response = await http.post(
    Uri.parse('$API_BASE_URL/vouchers/validate_voucher.php'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'voucher_code': voucherCode,
      'product_ids': productIds,
    }),
  );
  
  final data = json.decode(response.body);
  return VoucherValidationResult.fromJson(data['data']);
}
```

## Cấu trúc Database

### Bảng `vouchers`
```sql
CREATE TABLE `vouchers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `voucher_code` varchar(50) NOT NULL,
  `discount_amount` decimal(15,2) NOT NULL,
  `quantity` int(11) NOT NULL DEFAULT 1,
  `start_date` datetime NOT NULL,
  `end_date` datetime NOT NULL,
  `voucher_type` enum('all_products','specific_products','category_based') DEFAULT 'all_products',
  `category_filter` varchar(100) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `voucher_code` (`voucher_code`)
);
```

### Bảng `voucher_product_associations`
```sql
CREATE TABLE `voucher_product_associations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `voucher_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_voucher_product` (`voucher_id`, `product_id`),
  FOREIGN KEY (`voucher_id`) REFERENCES `vouchers` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
);
```

## Lưu ý quan trọng

1. **Bảo mật**: Chỉ admin mới có thể tạo/sửa/xóa voucher
2. **Validation**: Hệ thống tự động kiểm tra:
   - Thời gian hiệu lực
   - Số lượng còn lại
   - Tính khả dụng cho sản phẩm
3. **Performance**: Sử dụng index để tối ưu truy vấn
4. **Audit**: Tất cả thao tác được ghi log

## Troubleshooting

### Lỗi thường gặp

1. **"Voucher not found"**
   - Kiểm tra mã voucher có đúng không
   - Kiểm tra voucher có tồn tại trong database không

2. **"Voucher is not valid at this time"**
   - Kiểm tra ngày hiệu lực của voucher
   - Đảm bảo thời gian hiện tại nằm trong khoảng hiệu lực

3. **"Voucher is not applicable to any of the selected products"**
   - Kiểm tra loại voucher (all_products/specific_products/category_based)
   - Kiểm tra danh sách sản phẩm được liên kết

4. **"Voucher has been fully used"**
   - Kiểm tra số lượng còn lại của voucher
   - Tạo voucher mới nếu cần

## Phát triển tiếp theo

1. **Thống kê sử dụng voucher**
2. **Báo cáo hiệu quả voucher**
3. **Tích hợp với hệ thống thông báo**
4. **Auto-apply voucher cho khách hàng VIP**
5. **A/B testing cho voucher**

---

**Liên hệ hỗ trợ**: Nếu gặp vấn đề, vui lòng kiểm tra log và tạo ticket hỗ trợ. 