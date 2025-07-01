# Quản lý sản phẩm Agency - Hướng dẫn sử dụng

## Tổng quan
Tính năng quản lý sản phẩm Agency cho phép admin duyệt các sản phẩm được gửi lên từ các agency. Giao diện được chia thành 3 tab chính:

### 1. Tab "Chờ duyệt"
- Hiển thị danh sách sản phẩm có status = 'pending'
- Mỗi sản phẩm hiển thị:
  - Tên sản phẩm
  - Hình ảnh
  - Mô tả
  - Danh mục và đối tượng
  - Tổng số lượng và giá từ
  - Tên agency và email
- Có 2 nút hành động:
  - **Duyệt** (✓): Chuyển sản phẩm sang trạng thái 'approved'
  - **Từ chối** (✗): Chuyển sản phẩm sang trạng thái 'rejected' và yêu cầu nhập lý do

### 2. Tab "Đã duyệt"
- Hiển thị danh sách sản phẩm có status = 'approved'
- Thông tin hiển thị tương tự tab "Chờ duyệt"
- Thêm thông tin người duyệt và thời gian duyệt
- Hiển thị thông báo rằng sản phẩm sẽ được hiển thị trên app

### 3. Tab "Từ chối"
- Hiển thị danh sách sản phẩm có status = 'rejected'
- Hiển thị tên sản phẩm, tên agency và lý do từ chối
- Thông tin người từ chối và thời gian từ chối

## Cách sử dụng

### Truy cập tính năng
1. Đăng nhập vào admin panel
2. Chọn menu "Chờ duyệt" từ sidebar
3. Giao diện sẽ hiển thị với 3 tab

### Duyệt sản phẩm
1. Chuyển đến tab "Chờ duyệt"
2. Xem thông tin sản phẩm cần duyệt
3. Nhấn nút "Duyệt" để chấp nhận sản phẩm
4. Sản phẩm sẽ chuyển sang tab "Đã duyệt"

### Từ chối sản phẩm
1. Chuyển đến tab "Chờ duyệt"
2. Nhấn nút "Từ chối"
3. Nhập lý do từ chối trong dialog
4. Nhấn "Xác nhận"
5. Sản phẩm sẽ chuyển sang tab "Từ chối"

## API Endpoints

### Lấy danh sách sản phẩm
```
GET /API/admin/get_pending_products.php?status={status}
```
- `status`: 'pending', 'approved', 'rejected', hoặc 'all'

### Duyệt/từ chối sản phẩm
```
POST /API/admin/review_agency_product.php
```
Body:
```json
{
  "product_id": 123,
  "action": "approve|reject",
  "review_notes": "Lý do từ chối (nếu có)"
}
```

## Cấu trúc dữ liệu

### PendingProduct Model
```dart
class PendingProduct {
  final int id;
  final String name;
  final String description;
  final String category;
  final String genderTarget;
  final String? mainImage;
  final String status;
  final String agencyName;
  final String agencyEmail;
  final String agencyPhone;
  final String createdAt;
  final String updatedAt;
  final List<ProductVariant> variants;
  final String? reviewNotes;
  final String? reviewedAt;
  final String? reviewerName;
}
```

### ProductVariant Model
```dart
class ProductVariant {
  final int variantId;
  final String sku;
  final double price;
  final int stock;
  final String? imageUrl;
  final String variantStatus;
}
```

## Lưu ý quan trọng

### Về trạng thái sản phẩm
- **pending**: Sản phẩm chờ duyệt
- **approved**: Sản phẩm đã được duyệt (sẽ hiển thị trên app)
- **rejected**: Sản phẩm bị từ chối (không hiển thị trên app)

### Về hiển thị trên app
- Sản phẩm có status = 'approved' sẽ được hiển thị trên ứng dụng để khách hàng mua hàng
- Không cần thay đổi status thành 'active' vì logic hiện tại đã phù hợp

### Về thông báo
- Khi duyệt/từ chối sản phẩm, hệ thống sẽ tự động gửi thông báo cho agency
- Agency sẽ nhận được email thông báo về kết quả duyệt

## Troubleshooting

### Lỗi kết nối
- Kiểm tra URL API trong `PendingProductService.baseUrl`
- Đảm bảo server đang chạy
- Kiểm tra kết nối mạng

### Lỗi authentication
- Đảm bảo đã đăng nhập với quyền admin
- Kiểm tra token authentication trong service

### Lỗi hiển thị dữ liệu
- Kiểm tra format response từ API
- Đảm bảo database có dữ liệu sản phẩm agency
- Kiểm tra quyền truy cập database 