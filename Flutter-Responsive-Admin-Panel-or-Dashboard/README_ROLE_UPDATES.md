# Role-Based System Updates

## Tổng quan
Đã cập nhật hệ thống admin panel để hỗ trợ đầy đủ tính năng quản lý role (admin/user) cho người dùng.

## Các thay đổi đã thực hiện

### 1. Model Updates
- **File**: `lib/models/user_model.dart`
- **Thay đổi**: Thêm trường `role` vào User model
- **Kết quả**: Model User giờ yêu cầu tham số `role` khi tạo object

### 2. Backend API Updates

#### add_user.php
- **Thay đổi**: Thêm hỗ trợ tham số `Role` khi tạo user mới
- **Query**: `INSERT INTO nguoidung (Ten, MatKhau, SoDienThoai, Email, Role) VALUES (?, ?, ?, ?, ?)`
- **Default**: Role mặc định là 'user' nếu không được cung cấp

#### update_user.php
- **Thay đổi**: Thêm hỗ trợ cập nhật tham số `Role`
- **Query**: `UPDATE nguoidung SET Ten=?, MatKhau=?, SoDienThoai=?, Email=?, Role=? WHERE MaND=?`

#### get_users.php
- **Thay đổi**: Thêm trường `Role` vào SELECT query
- **Query**: `SELECT MaND, Ten, MatKhau, SoDienThoai, Email, Role FROM nguoidung`

### 3. Frontend Updates

#### AddEditUserScreen (`lib/screens/user/add_edit_user_screen.dart`)
- **Thay đổi**: 
  - Thêm dropdown để chọn role (admin/user)
  - Cập nhật logic tạo User object với tham số role
  - Gửi tham số Role trong API request
- **Giao diện**: Dropdown với 2 lựa chọn: "Người dùng" và "Quản trị viên"

#### UserTable (`lib/screens/user/components/user_table.dart`)
- **Thay đổi**:
  - Thêm cột "Vai trò" vào bảng
  - Hiển thị role với màu sắc khác nhau:
    - Admin: Màu đỏ
    - User: Màu xanh
  - Hiển thị tên tiếng Việt cho role

## Cách sử dụng

### 1. Thêm User mới
1. Vào màn hình "Quản lý người dùng"
2. Click "Thêm người dùng"
3. Điền thông tin và chọn vai trò từ dropdown
4. Click "Lưu"

### 2. Sửa User
1. Click icon edit (✏️) bên cạnh user cần sửa
2. Thay đổi thông tin và/và vai trò
3. Click "Lưu"

### 3. Xem danh sách User
- Bảng hiển thị đầy đủ thông tin bao gồm vai trò
- Vai trò được hiển thị với màu sắc và tên tiếng Việt

## Các giá trị Role
- `admin`: Quản trị viên (hiển thị màu đỏ)
- `user`: Người dùng thường (hiển thị màu xanh)

## Lưu ý
- Role mặc định khi tạo user mới là 'user'
- Có thể thay đổi role của user bất kỳ lúc nào
- Role được lưu trữ trong database và hiển thị trong admin panel
- Hệ thống role-based navigation đã được tích hợp với userfe app

## Testing
1. Chạy admin panel: `flutter run`
2. Thử thêm/sửa user với các role khác nhau
3. Kiểm tra hiển thị trong bảng user
4. Test với userfe app để xác nhận role-based navigation hoạt động 