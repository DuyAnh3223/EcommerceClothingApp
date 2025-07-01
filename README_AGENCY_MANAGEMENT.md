# Hệ thống quản lý Agency - Ecommerce Clothing App

## Tổng quan

Hệ thống quản lý Agency cho phép các đối tác (agency) quản lý sản phẩm, thuộc tính và biến thể của riêng họ, tương tự như admin nhưng chỉ trong phạm vi sản phẩm của agency đó.

## Cấu trúc API

### 1. Quản lý sản phẩm

#### Thêm sản phẩm mới
```
POST /API/agency/products/add_product.php
```
**Body:**
```json
{
  "name": "Tên sản phẩm",
  "description": "Mô tả sản phẩm",
  "category": "Danh mục",
  "gender_target": "male|female|unisex",
  "main_image": "URL hình ảnh (optional)"
}
```

#### Lấy danh sách sản phẩm
```
GET /API/agency/products/get_products.php?status=all&page=1&limit=10
```

#### Cập nhật sản phẩm
```
PUT /API/agency/products/update_product.php
```
**Body:**
```json
{
  "product_id": 123,
  "name": "Tên mới (optional)",
  "description": "Mô tả mới (optional)",
  "category": "Danh mục mới (optional)",
  "gender_target": "male|female|unisex (optional)",
  "main_image": "URL hình ảnh mới (optional)"
}
```

#### Xóa sản phẩm
```
DELETE /API/agency/products/delete_product.php
```
**Body:**
```json
{
  "product_id": 123
}
```

#### Gửi sản phẩm để duyệt
```
POST /API/agency/submit_for_approval.php
```
**Body:**
```json
{
  "product_id": 123
}
```

### 2. Quản lý thuộc tính

#### Thêm thuộc tính mới
```
POST /API/agency/variants_attributes/add_attribute.php
```
**Body:**
```json
{
  "name": "Tên thuộc tính"
}
```

#### Lấy danh sách thuộc tính
```
GET /API/agency/variants_attributes/get_attributes.php
```

#### Thêm giá trị thuộc tính
```
POST /API/agency/variants_attributes/add_attribute_value.php
```
**Body:**
```json
{
  "attribute_id": 123,
  "value": "Giá trị thuộc tính"
}
```

### 3. Quản lý biến thể

#### Thêm biến thể mới
```
POST /API/agency/variants_attributes/add_variant.php
```
**Body:**
```json
{
  "product_id": 123,
  "price": 100000,
  "stock": 50,
  "attribute_values": [1, 2, 3],
  "image_url": "URL hình ảnh (optional)"
}
```

#### Lấy danh sách biến thể
```
GET /API/agency/variants_attributes/get_variants.php?product_id=123
```

## Giao diện Flutter

### Màn hình chính

#### AgencyDashboardScreen
- Màn hình dashboard chính với bottom navigation
- Chuyển đổi giữa 3 chức năng: Sản phẩm, Thuộc tính, Biến thể

#### AgencyProductManagementScreen
- Hiển thị danh sách sản phẩm với 4 tab: Tất cả, Nháp, Chờ duyệt, Đã duyệt
- Chức năng: Thêm, sửa, xóa, gửi duyệt sản phẩm
- Hiển thị trạng thái và thông tin chi tiết sản phẩm

#### AgencyAttributeManagementScreen
- Quản lý thuộc tính và giá trị thuộc tính
- Thêm thuộc tính mới và giá trị cho từng thuộc tính
- Hiển thị dạng ExpansionTile với danh sách giá trị

#### AgencyVariantManagementScreen
- Quản lý biến thể sản phẩm
- Hiển thị thông tin: SKU, giá, tồn kho, thuộc tính
- Chỉnh sửa và xóa biến thể (khi sản phẩm ở trạng thái nháp/từ chối)

### Models

#### AgencyProduct
```dart
class AgencyProduct {
  final int id;
  final String name;
  final String description;
  final String category;
  final String genderTarget;
  final String? mainImage;
  final bool isAgencyProduct;
  final String status;
  final double platformFeeRate;
  final String createdAt;
  final String updatedAt;
  final String? approvalStatus;
  final String? reviewNotes;
  final String? reviewedAt;
  final String? reviewerName;
  final List<ProductVariant> variants;
}
```

#### ProductVariant
```dart
class ProductVariant {
  final int variantId;
  final String sku;
  final double price;
  final int stock;
  final String? imageUrl;
  final String variantStatus;
  final Map<String, String> attributes;
}
```

#### Attribute
```dart
class Attribute {
  final int id;
  final String name;
  final String createdAt;
  final String? createdByName;
  final List<AttributeValue> values;
}
```

### Services

#### AgencyService
- `getProducts()`: Lấy danh sách sản phẩm
- `addProduct()`: Thêm sản phẩm mới
- `updateProduct()`: Cập nhật sản phẩm
- `deleteProduct()`: Xóa sản phẩm
- `submitForApproval()`: Gửi sản phẩm để duyệt
- `getAttributes()`: Lấy danh sách thuộc tính
- `addAttribute()`: Thêm thuộc tính mới
- `addAttributeValue()`: Thêm giá trị thuộc tính
- `getVariants()`: Lấy danh sách biến thể
- `addVariant()`: Thêm biến thể mới

## Quy trình làm việc

### 1. Tạo sản phẩm mới
1. Agency tạo sản phẩm với trạng thái "draft"
2. Thêm các thuộc tính và giá trị thuộc tính cần thiết
3. Tạo các biến thể cho sản phẩm
4. Gửi sản phẩm để admin duyệt

### 2. Quy trình duyệt
1. Sản phẩm được gửi với trạng thái "pending"
2. Admin xem xét và duyệt/từ chối
3. Nếu từ chối, agency có thể chỉnh sửa và gửi lại
4. Nếu duyệt, sản phẩm hiển thị cho khách hàng

### 3. Quản lý trạng thái
- **draft**: Sản phẩm nháp, có thể chỉnh sửa
- **pending**: Chờ admin duyệt
- **approved**: Đã được duyệt, hiển thị cho khách hàng
- **rejected**: Bị từ chối, có thể chỉnh sửa và gửi lại

## Bảo mật

- Tất cả API đều yêu cầu authentication với role "agency"
- Agency chỉ có thể quản lý sản phẩm của chính mình
- Không thể chỉnh sửa sản phẩm đã được duyệt
- Validation đầy đủ cho tất cả input

## Lưu ý

1. Sản phẩm phải có ít nhất 1 biến thể trước khi gửi duyệt
2. Chỉ có thể chỉnh sửa sản phẩm ở trạng thái "draft" hoặc "rejected"
3. Phí nền tảng mặc định là 20% cho sản phẩm agency
4. Tất cả thao tác đều được ghi log với thông tin người thực hiện

## Troubleshooting

### Lỗi thường gặp

1. **403 Forbidden**: Kiểm tra authentication và role
2. **400 Bad Request**: Kiểm tra dữ liệu đầu vào
3. **404 Not Found**: Kiểm tra ID sản phẩm/thuộc tính/biến thể
4. **409 Conflict**: Dữ liệu đã tồn tại

### Debug

- Kiểm tra response từ API để xem thông báo lỗi chi tiết
- Sử dụng network tab trong browser developer tools
- Kiểm tra log server để xem lỗi backend 