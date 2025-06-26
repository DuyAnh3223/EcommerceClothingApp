# Chức năng Đăng xuất (Logout)

## Tổng quan
Chức năng đăng xuất cho phép user thoát khỏi ứng dụng và xóa thông tin đăng nhập đã lưu.

## Cách sử dụng

### 1. Nút đăng xuất trong AppBar
- Nhấn vào icon **logout** (🚪) ở góc phải trên cùng của AppBar
- Hoặc nhấn vào icon **person** (👤) và chọn "Đăng xuất" từ menu

### 2. Quy trình đăng xuất
1. Hiển thị dialog xác nhận "Bạn có chắc chắn muốn đăng xuất?"
2. Nhấn "Đăng xuất" để xác nhận
3. Hiển thị thông báo "Đang đăng xuất..."
4. Gọi API logout từ server (nếu có)
5. Xóa dữ liệu user khỏi SharedPreferences
6. Hiển thị thông báo "Đã đăng xuất thành công"
7. Chuyển về màn hình đăng nhập

## Tính năng

### ✅ Xác nhận đăng xuất
- Dialog xác nhận trước khi đăng xuất
- Có thể hủy bỏ nếu nhấn nhầm

### ✅ Xử lý lỗi
- Nếu server logout thất bại, vẫn logout local
- Đảm bảo user luôn có thể đăng xuất

### ✅ Thông báo rõ ràng
- Loading indicator khi đang đăng xuất
- Thông báo thành công/thất bại
- Tooltip cho nút đăng xuất

### ✅ Navigation
- Xóa tất cả màn hình trong stack
- Chuyển về Login Screen
- Không thể quay lại bằng nút back

## API Endpoints

### POST `/users/logout.php`
- **Purpose**: Thông báo server về việc đăng xuất
- **Response**: 
```json
{
  "success": true,
  "message": "Đăng xuất thành công"
}
```

## Local Storage

### Dữ liệu bị xóa khi logout:
- `user_data`: Thông tin user
- `user_role`: Role của user

### Dữ liệu được lưu trong SharedPreferences:
- Được xóa hoàn toàn khi logout
- Không thể khôi phục trừ khi đăng nhập lại

## Bảo mật

### ✅ Xóa dữ liệu local
- Xóa thông tin user khỏi SharedPreferences
- Xóa role và session data

### ✅ Navigation security
- Xóa toàn bộ navigation stack
- Không thể quay lại màn hình đã đăng nhập

### ✅ Server notification
- Thông báo server về việc đăng xuất
- Có thể tracking session nếu cần

## Lưu ý

1. **Không thể hoàn tác**: Sau khi đăng xuất, user phải đăng nhập lại
2. **Xóa dữ liệu**: Tất cả thông tin user sẽ bị xóa khỏi thiết bị
3. **Navigation**: Không thể quay lại bằng nút back sau khi đăng xuất
4. **Offline support**: Có thể đăng xuất ngay cả khi không có kết nối internet

## Troubleshooting

### Lỗi "Không thể đăng xuất"
- Kiểm tra kết nối internet
- Thử lại sau vài giây
- Restart app nếu cần

### Lỗi "Vẫn còn thông tin user"
- Đảm bảo đã gọi `AuthService.logout()`
- Kiểm tra SharedPreferences đã được xóa
- Restart app để refresh state 