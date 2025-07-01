# Hướng dẫn Test Agency Management

## Bước 1: Tạo dữ liệu test

Chạy file `test_create_agency_user.php` để tạo:
- User agency với thông tin:
  - Username: `agency_test`
  - Email: `agency@gmail.com`
  - Password: `123456`
  - Role: `agency`

- Sản phẩm mẫu:
  - "Áo thun Agency Test" (status: pending)
  - "Quần jean Agency Test" (status: draft)
  - Variant với attributes: color=black, size=X

## Bước 2: Test API get_products

Chạy file `test_agency_get_products.php` để test API lấy danh sách sản phẩm của agency.

## Bước 3: Test Flutter App

1. Đăng nhập vào Flutter app với tài khoản agency:
   - Username: `agency_test`
   - Password: `123456`

2. Kiểm tra các chức năng:
   - Quản lý sản phẩm
   - Quản lý thuộc tính
   - Quản lý variants
   - Submit sản phẩm để duyệt

## Cấu trúc dữ liệu trả về

API `get_products.php` sẽ trả về:

```json
{
  "success": true,
  "message": "Products retrieved successfully",
  "data": {
    "products": [
      {
        "id": 8,
        "name": "Áo thun Agency Test",
        "description": "Sản phẩm test do agency tạo ra",
        "category": "T-Shirts",
        "gender_target": "unisex",
        "main_image": "test_agency_product.jpg",
        "created_by": 7,
        "is_agency_product": 1,
        "status": "pending",
        "platform_fee_rate": "20.00",
        "created_at": "2025-01-01 10:00:00",
        "updated_at": "2025-01-01 10:00:00",
        "approval_status": null,
        "review_notes": null,
        "reviewed_at": null,
        "reviewer_name": null,
        "variants": [
          {
            "id": 12,
            "sku": "AGENCY-TEST-001",
            "price": "150000.00",
            "stock": 50,
            "image_url": null,
            "status": "active",
            "product_id": 8,
            "attributes": [
              {
                "id": 16,
                "value": "black",
                "attribute_id": 1,
                "attribute_name": "color"
              },
              {
                "id": 12,
                "value": "X",
                "attribute_id": 2,
                "attribute_name": "size"
              }
            ]
          }
        ]
      }
    ],
    "total": 2,
    "page": 1,
    "limit": 10
  }
}
```

## Troubleshooting

1. **Lỗi "No agency user found"**: Chạy `test_create_agency_user.php` trước
2. **Lỗi authentication**: Kiểm tra session và role trong database
3. **Lỗi database**: Kiểm tra kết nối database và quyền truy cập 