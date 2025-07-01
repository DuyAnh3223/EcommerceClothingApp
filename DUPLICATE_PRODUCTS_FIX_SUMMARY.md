# Duplicate Products Fix Summary

## Vấn đề
Khi agency gửi duyệt sản phẩm, trong danh sách sản phẩm hiển thị duplicate (mỗi sản phẩm xuất hiện 2 lần) mặc dù trong database chỉ có 1 sản phẩm.

## Nguyên nhân
1. **Duplicate records trong bảng `product_approvals`**: Mỗi sản phẩm có nhiều records trong bảng này:
   - Record đầu tiên khi tạo sản phẩm (status rỗng "")
   - Record thứ hai khi gửi duyệt (status "pending")
   - Record thứ ba khi approve (status "approved")

2. **Query SQL không xử lý duplicate**: API `get_products.php` sử dụng LEFT JOIN với bảng `product_approvals` mà không có logic để lấy record mới nhất hoặc duy nhất.

## Giải pháp đã áp dụng

### 1. Sửa query SQL trong API
**File**: `API/agency/products/get_products.php`

**Thay đổi**: Sử dụng subquery để lấy record mới nhất từ bảng `product_approvals`:

```sql
LEFT JOIN (
    SELECT pa1.*
    FROM product_approvals pa1
    INNER JOIN (
        SELECT product_id, MAX(created_at) as max_created_at
        FROM product_approvals
        GROUP BY product_id
    ) pa2 ON pa1.product_id = pa2.product_id AND pa1.created_at = pa2.max_created_at
) pa ON p.id = pa.product_id
```

### 2. Thêm logic duplicate prevention trong PHP
**File**: `API/agency/products/get_products.php`

**Thay đổi**: Thêm logic để track và skip duplicate products:

```php
$seen_products = []; // Track seen product IDs to avoid duplicates

while ($row = $result->fetch_assoc()) {
    // Skip if we've already processed this product
    if (in_array($row['id'], $seen_products)) {
        continue;
    }
    
    $seen_products[] = $row['id'];
    // ... rest of processing
}
```

### 3. Loại bỏ debug statements
**Files**: 
- `userfe/lib/services/agency_service.dart`
- `userfe/lib/screens/agency/agency_product_screen.dart`
- `userfe/lib/models/agency_product_model.dart`

**Thay đổi**: Loại bỏ tất cả debug print statements để clean up code.

## Kết quả
- API trả về đúng 3 sản phẩm thay vì 6 (duplicate)
- Flutter app hiển thị đúng danh sách sản phẩm không bị duplicate
- Không còn vấn đề khi gửi duyệt sản phẩm

## Test
Đã test bằng script `API/tests/test_agency_products_duplicate.php` và xác nhận:
- Total products found: 3 (thay vì 6)
- Mỗi sản phẩm chỉ xuất hiện 1 lần
- Approval status hiển thị đúng (pending, approved)

## Lưu ý
- Vấn đề duplicate chỉ xảy ra ở phía API, không phải ở database
- Database chỉ có 3 sản phẩm thật, nhưng query trả về 6 records do JOIN với bảng `product_approvals`
- Giải pháp đảm bảo chỉ lấy record mới nhất từ bảng `product_approvals` cho mỗi sản phẩm 