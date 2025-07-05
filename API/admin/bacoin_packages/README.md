# BACoin Packages Management API

## Tổng quan
API này cho phép admin quản lý các gói BACoin trong hệ thống e-commerce.

## Endpoints

### 1. Lấy danh sách gói BACoin
- **URL**: `GET /admin/bacoin_packages/get_packages.php`
- **Mô tả**: Lấy tất cả gói BACoin có trong hệ thống
- **Response**:
```json
{
  "status": 200,
  "message": "Success",
  "data": [
    {
      "id": 1,
      "package_name": "Gói 50K",
      "price_vnd": "50000.00",
      "bacoin_amount": "55000.00",
      "description": "Gói nạp BACoin trị giá 50.000 VNĐ"
    }
  ]
}
```

### 2. Thêm gói BACoin mới
- **URL**: `POST /admin/bacoin_packages/add_package.php`
- **Mô tả**: Thêm gói BACoin mới vào hệ thống
- **Request Body**:
```json
{
  "package_name": "Gói 200K",
  "price_vnd": 200000,
  "bacoin_amount": 250000,
  "description": "Gói nạp BACoin trị giá 200.000 VNĐ"
}
```
- **Response**:
```json
{
  "status": 201,
  "message": "Package created successfully",
  "data": {
    "id": 6,
    "package_name": "Gói 200K",
    "price_vnd": "200000.00",
    "bacoin_amount": "250000.00",
    "description": "Gói nạp BACoin trị giá 200.000 VNĐ"
  }
}
```

### 3. Cập nhật gói BACoin
- **URL**: `PUT /admin/bacoin_packages/update_package.php`
- **Mô tả**: Cập nhật thông tin gói BACoin
- **Request Body**:
```json
{
  "id": 1,
  "package_name": "Gói 50K Updated",
  "price_vnd": 50000,
  "bacoin_amount": 60000,
  "description": "Gói 50K đã được cập nhật"
}
```
- **Response**:
```json
{
  "status": 200,
  "message": "Package updated successfully",
  "data": {
    "id": 1,
    "package_name": "Gói 50K Updated",
    "price_vnd": "50000.00",
    "bacoin_amount": "60000.00",
    "description": "Gói 50K đã được cập nhật"
  }
}
```

### 4. Xóa gói BACoin
- **URL**: `DELETE /admin/bacoin_packages/delete_package.php`
- **Mô tả**: Xóa gói BACoin khỏi hệ thống
- **Request Body**:
```json
{
  "id": 6
}
```
- **Response**:
```json
{
  "status": 200,
  "message": "Package deleted successfully",
  "data": null
}
```

## Validation Rules

### Thêm/Cập nhật gói:
- `package_name`: Bắt buộc, không được trống
- `price_vnd`: Bắt buộc, phải là số dương
- `bacoin_amount`: Bắt buộc, phải là số dương
- `description`: Tùy chọn

### Xóa gói:
- `id`: Bắt buộc, phải là ID hợp lệ

## Error Responses

### 400 Bad Request
```json
{
  "status": 400,
  "message": "Missing required field: package_name",
  "data": null
}
```

### 403 Unauthorized
```json
{
  "status": 403,
  "message": "Unauthorized",
  "data": null
}
```

### 404 Not Found
```json
{
  "status": 404,
  "message": "Package not found",
  "data": null
}
```

### 500 Internal Server Error
```json
{
  "status": 500,
  "message": "Database error: [error details]",
  "data": null
}
```

## Testing

Để test API, sử dụng file `../tests/test_bacoin_packages.php`:

```bash
# Truy cập file test trong trình duyệt
http://localhost/EcommerceClothingApp/API/tests/test_bacoin_packages.php
```

## Flutter Integration

Giao diện admin Flutter đã được tích hợp với các tính năng:
- Hiển thị danh sách gói BACoin
- Thêm gói mới
- Sửa gói hiện có
- Xóa gói
- Validation form
- Loading states và error handling

### Cách sử dụng trong Flutter:
1. Import service: `import '../../services/bacoin_package_service.dart';`
2. Import model: `import '../../models/bacoin_package_model.dart';`
3. Import screen: `import '../bacoin_package/bacoin_package_screen.dart';`

### Navigation:
Menu "Quản lý Gói BACoin" đã được thêm vào sidebar của admin panel. 