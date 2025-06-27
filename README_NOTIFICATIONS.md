# Hệ thống Thông báo (Notifications System)

## Tổng quan
Hệ thống thông báo cho phép admin gửi thông báo đến người dùng và tự động gửi thông báo khi có thay đổi trạng thái đơn hàng.

## Tính năng

### 1. Backend APIs

#### Các API chính:
- `GET /notifications/get_notifications.php` - Lấy danh sách thông báo với phân trang và lọc
- `GET /notifications/get_unread_count.php` - Lấy số thông báo chưa đọc
- `POST /notifications/mark_read.php` - Đánh dấu thông báo đã đọc
- `POST /notifications/add_notification.php` - Tạo thông báo mới
- `POST /notifications/send_order_notification.php` - Gửi thông báo tự động khi thay đổi trạng thái đơn hàng

#### API Test:
- `GET/POST /test_notifications.php` - Test và thêm dữ liệu mẫu

### 2. Frontend (User App)

#### Màn hình chính:
- **NotificationsScreen** (`userfe/lib/screens/notifications/notifications_screen.dart`)
  - Hiển thị danh sách thông báo với phân trang
  - Lọc theo loại thông báo và trạng thái đọc
  - Đánh dấu đã đọc (từng thông báo hoặc tất cả)
  - Pull-to-refresh để tải lại dữ liệu

#### Tích hợp:
- **HomeScreen**: Nút thông báo với badge hiển thị số thông báo chưa đọc
- **NotificationService**: Service để gọi các API thông báo

### 3. Admin Panel

#### Màn hình quản lý:
- **NotificationManagementScreen** (`Flutter-Responsive-Admin-Panel-or-Dashboard/lib/screens/notifications/notification_management_screen.dart`)
  - Gửi thông báo đến tất cả người dùng hoặc người dùng cụ thể
  - Chọn loại thông báo (order_status, sale, voucher, other)
  - Thống kê số lượng người dùng

#### Menu:
- Thêm menu "Thông báo" vào sidebar
- Icon: `assets/icons/thongbao.svg`

## Cấu trúc Database

### Bảng `notifications`:
```sql
CREATE TABLE `notifications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `content` text DEFAULT NULL,
  `type` enum('order_status','sale','voucher','other') DEFAULT 'other',
  `is_read` tinyint(1) DEFAULT 0,
  `created_at` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
);
```

## Cách sử dụng

### 1. Test API
```bash
# Thêm thông báo mẫu
curl -X POST http://127.0.0.1/EcommerceClothingApp/API/test_notifications.php \
  -H "Content-Type: application/json" \
  -d '{"action": "add_samples"}'

# Xem tất cả thông báo
curl http://127.0.0.1/EcommerceClothingApp/API/test_notifications.php

# Xóa tất cả thông báo
curl -X POST http://127.0.0.1/EcommerceClothingApp/API/test_notifications.php \
  -H "Content-Type: application/json" \
  -d '{"action": "clear_all"}'
```

### 2. Gửi thông báo từ Admin
1. Đăng nhập vào Admin Panel
2. Chọn menu "Thông báo"
3. Điền thông tin:
   - Gửi đến: Tất cả người dùng hoặc người dùng cụ thể
   - Loại thông báo: Chọn loại phù hợp
   - Tiêu đề: Bắt buộc
   - Nội dung: Tùy chọn
4. Nhấn "Gửi thông báo"

### 3. Xem thông báo từ User App
1. Đăng nhập vào User App
2. Nhấn nút thông báo (có badge đỏ nếu có thông báo chưa đọc)
3. Xem danh sách thông báo
4. Sử dụng bộ lọc để tìm thông báo cụ thể
5. Nhấn vào thông báo để đánh dấu đã đọc

## Tự động hóa

### Thông báo đơn hàng:
- Khi admin cập nhật trạng thái đơn hàng, hệ thống tự động gửi thông báo đến người dùng
- Các trạng thái được hỗ trợ:
  - `confirmed`: Đơn hàng đã được xác nhận
  - `shipping`: Đơn hàng đang được giao
  - `delivered`: Đơn hàng đã được giao thành công
  - `cancelled`: Đơn hàng đã bị hủy

## Loại thông báo

1. **order_status**: Thông báo về trạng thái đơn hàng
2. **sale**: Thông báo khuyến mãi, giảm giá
3. **voucher**: Thông báo voucher, mã giảm giá
4. **other**: Thông báo khác

## Tính năng nâng cao

### Phân trang:
- Mặc định 20 thông báo mỗi trang
- Load more khi cuộn xuống cuối

### Lọc:
- Theo loại thông báo
- Theo trạng thái đọc (đã đọc/chưa đọc)

### Badge:
- Hiển thị số thông báo chưa đọc trên nút thông báo
- Tự động cập nhật khi có thông báo mới

### Pull-to-refresh:
- Kéo xuống để tải lại danh sách thông báo

## Troubleshooting

### Lỗi thường gặp:
1. **Thông báo không hiển thị**: Kiểm tra kết nối database và API
2. **Badge không cập nhật**: Gọi lại `_loadNotificationCount()` sau khi quay về từ màn hình thông báo
3. **Thông báo tự động không gửi**: Kiểm tra API `send_order_notification.php` và cấu hình server

### Debug:
- Sử dụng `test_notifications.php` để kiểm tra dữ liệu
- Kiểm tra logs của web server
- Test API bằng Postman hoặc curl 