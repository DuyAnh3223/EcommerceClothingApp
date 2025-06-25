# UserFE - Shopping App

## Mô tả
Ứng dụng mua sắm dành cho người dùng cuối, được xây dựng bằng Flutter và tích hợp với API backend PHP.

## Tính năng
- ✅ Đăng nhập người dùng
- ✅ Hiển thị danh sách sản phẩm
- ✅ Tìm kiếm sản phẩm
- ✅ Giao diện đẹp và thân thiện
- ✅ Tích hợp với API backend
- ✅ Responsive design

## Cấu trúc thư mục

```
lib/
├── screens/
│   ├── auth/
│   │   └── login_screen.dart      # Màn hình đăng nhập
│   └── home/
│       └── home_screen.dart       # Màn hình trang chủ
├── services/
│   └── auth_service.dart          # Service xử lý API calls
└── main.dart                      # Entry point với routes
```

## Cách sử dụng

### 1. Cài đặt dependencies
```bash
flutter pub get
```

### 2. Đảm bảo backend đang chạy
- WAMP/XAMPP phải được khởi động
- Apache và MySQL phải đang chạy
- Database `quanlybanhang` phải được import

### 3. Chạy ứng dụng
```bash
flutter run
```

## API Endpoints sử dụng

### Login
- **URL**: `http://localhost/MyProject/backendapi/users/login.php`
- **Method**: POST
- **Body**: 
  ```json
  {
    "Email": "string",
    "MatKhau": "string"
  }
  ```

### Get Products
- **URL**: `http://localhost/MyProject/backendapi/products/get_products.php`
- **Method**: GET

### Register User
- **URL**: `http://localhost/MyProject/backendapi/users/add_user.php`
- **Method**: POST
- **Body**:
  ```json
  {
    "Ten": "string",
    "Email": "string",
    "MatKhau": "string",
    "SoDienThoai": "string"
  }
  ```

## Tùy chỉnh

### Thay đổi URL API
Chỉnh sửa file `lib/services/auth_service.dart`:
```dart
static const String baseUrl = 'http://your-domain.com/your-project/backendapi';
```

### Thay đổi theme
Chỉnh sửa file `lib/main.dart` để thay đổi:
- Màu sắc chủ đạo
- Theme của ứng dụng

## Troubleshooting

### Lỗi kết nối
- Kiểm tra WAMP/XAMPP đang chạy
- Kiểm tra URL API đúng
- Kiểm tra firewall/antivirus

### Lỗi CORS
Backend đã có CORS headers, nếu vẫn lỗi thêm vào backend:
```php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
```

### Lỗi database
- Kiểm tra MySQL đang chạy
- Kiểm tra database `quanlybanhang` đã được import
- Kiểm tra file `config/db_connect.php` có thông tin kết nối đúng
