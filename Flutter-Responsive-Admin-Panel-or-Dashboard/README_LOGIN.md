# Login Screen - Flutter Admin Panel

## Mô tả
Screen đăng nhập được tạo để tích hợp với API backend PHP. Screen này sử dụng API endpoint `http://localhost/MyProject/backendapi/users/login.php` để xác thực người dùng.

## Tính năng
- ✅ Giao diện đẹp với gradient background
- ✅ Form validation cho email và password
- ✅ Loading indicator khi đang xử lý
- ✅ Hiển thị/ẩn password
- ✅ Thông báo lỗi/thành công
- ✅ Tích hợp với API backend
- ✅ Navigation tự động sau khi đăng nhập thành công

## Cách sử dụng

### 1. Cài đặt dependencies
Chạy lệnh sau để cài đặt các package cần thiết:
```bash
flutter pub get
```

### 2. Đảm bảo backend đang chạy
- WAMP/XAMPP phải được khởi động
- Apache và MySQL phải đang chạy
- Database `quanlybanhang` phải được import

### 3. Test API với Postman
Trước khi test Flutter app, bạn có thể test API với Postman:

**POST** `http://localhost/MyProject/backendapi/users/login.php`
```json
{
    "Email": "admin@example.com",
    "MatKhau": "password123"
}
```

### 4. Chạy Flutter app
```bash
flutter run
```

## Cấu trúc file

```
lib/
├── screens/
│   └── auth/
│       └── login_screen.dart      # Screen đăng nhập
├── services/
│   └── auth_service.dart          # Service xử lý API calls
└── main.dart                      # Entry point với routes
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
- **Response Success**:
  ```json
  {
    "success": true,
    "message": "Đăng nhập thành công",
    "user": {
      "MaND": "1",
      "Ten": "Admin User",
      "Email": "admin@example.com",
      "SoDienThoai": "0123456789"
    }
  }
  ```
- **Response Error**:
  ```json
  {
    "success": false,
    "message": "Email hoặc mật khẩu không đúng"
  }
  ```

## Tùy chỉnh

### Thay đổi URL API
Chỉnh sửa file `lib/services/auth_service.dart`:
```dart
static const String baseUrl = 'http://your-domain.com/your-project/backendapi';
```

### Thay đổi giao diện
Chỉnh sửa file `lib/screens/auth/login_screen.dart` để thay đổi:
- Màu sắc
- Layout
- Validation rules
- Navigation logic

## Troubleshooting

### Lỗi kết nối
- Kiểm tra WAMP/XAMPP đang chạy
- Kiểm tra URL API đúng
- Kiểm tra firewall/antivirus

### Lỗi CORS
- Backend đã có CORS headers
- Nếu vẫn lỗi, thêm vào backend:
```php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
```

### Lỗi database
- Kiểm tra MySQL đang chạy
- Kiểm tra database `quanlybanhang` đã được import
- Kiểm tra file `config/db_connect.php` có thông tin kết nối đúng 