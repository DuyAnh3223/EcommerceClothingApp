# Role-Based Navigation System

## Tổng quan
Hệ thống đã được cập nhật để hỗ trợ phân quyền dựa trên role (admin/user). Khi đăng nhập thành công, người dùng sẽ được điều hướng đến màn hình phù hợp với role của họ.

## Các thay đổi đã thực hiện

### 1. Cơ sở dữ liệu
- Đã thêm trường `Role` vào bảng `nguoidung` với các giá trị: `admin` hoặc `user`
- Cập nhật API login để trả về thông tin role

### 2. Backend API
- **File**: `backendapi/users/login.php`
- **Thay đổi**: Thêm trường `Role` vào câu query SELECT
- **Kết quả**: API trả về thông tin role của user

### 3. Flutter App

#### AuthService (`lib/services/auth_service.dart`)
- Thêm dependency `shared_preferences` để lưu trữ thông tin user
- Các method mới:
  - `_saveUserData()`: Lưu thông tin user vào local storage
  - `getUserData()`: Lấy thông tin user từ local storage
  - `getUserRole()`: Lấy role của user
  - `logout()`: Xóa thông tin user và đăng xuất
  - `isLoggedIn()`: Kiểm tra trạng thái đăng nhập

#### Admin Dashboard (`lib/screens/dashboard/admin_dashboard_screen.dart`)
- Tạo màn hình dashboard dành riêng cho admin
- Giao diện bao gồm:
  - Sidebar với thông tin user và menu navigation
  - Dashboard chính với các thống kê
  - Các tab quản lý: Sản phẩm, Đơn hàng, Người dùng
  - Nút logout

#### Login Screen (`lib/screens/auth/login_screen.dart`)
- Cập nhật logic điều hướng sau khi đăng nhập
- Kiểm tra role và điều hướng đến màn hình phù hợp:
  - `admin` → Admin Dashboard
  - `user` → Home Screen

#### Main App (`lib/main.dart`)
- Thêm SplashScreen để kiểm tra trạng thái đăng nhập
- Tự động điều hướng dựa trên role khi khởi động app

## Cách sử dụng

### 1. Đăng nhập với tài khoản Admin
```
Email: admin@gmail.com
Password: admin123
```
→ Sẽ được điều hướng đến Admin Dashboard

### 2. Đăng nhập với tài khoản User thường
```
Email: user@example.com
Password: user123
```
→ Sẽ được điều hướng đến Home Screen

### 3. Các tài khoản mẫu trong database
- **Admin**: `admin@gmail.com` / `admin123`
- **User**: `user@example.com` / `user123`
- **Admin khác**: `vana@example.com` / `123456412`

## Tính năng Admin Dashboard

### Dashboard Home
- Hiển thị các thống kê tổng quan
- Số lượng sản phẩm, đơn hàng, người dùng, doanh thu

### Quản lý Sản phẩm
- (Sẽ được phát triển thêm)

### Quản lý Đơn hàng
- (Sẽ được phát triển thêm)

### Quản lý Người dùng
- (Sẽ được phát triển thêm)

## Cài đặt và chạy

1. Cài đặt dependencies:
```bash
flutter pub get
```

2. Đảm bảo backend API đang chạy trên localhost

3. Chạy ứng dụng:
```bash
flutter run
```

## Lưu ý
- Thông tin user được lưu trong local storage (SharedPreferences)
- Khi logout, tất cả thông tin user sẽ bị xóa
- App sẽ tự động kiểm tra trạng thái đăng nhập khi khởi động
- Role-based navigation hoạt động tự động dựa trên thông tin từ database 