# Payment Dashboard - Admin Panel

## Tổng quan
Dashboard Thanh toán (Payment Dashboard) là một tính năng mới trong Admin Panel cho phép admin xem chi tiết đơn hàng và thông tin thanh toán.

## Tính năng chính

### 1. Giao diện chi tiết đơn hàng
Khi admin chọn một đơn hàng trong bảng orders, hiển thị thông tin chi tiết:

#### 📋 Thông tin hiển thị:
- **Mã đơn hàng** (#21)
- **Thông tin khách hàng**: Tên, Email, SĐT
- **Địa chỉ giao hàng**: Từ bảng `user_addresses`
- **Ngày đặt hàng**
- **Tổng tiền**
- **Trạng thái đơn hàng** (Dropdown chọn trạng thái)

#### 🧾 Lịch sử thanh toán (bảng payments)
- **Phương thức thanh toán**: COD, Momo, Bank, VNPAY, Other
- **Mã giao dịch**
- **Trạng thái thanh toán**: pending / paid / failed / refunded
- **Số tiền đã thanh toán**
- **Ngày thanh toán**

### 2. Logic hiển thị thanh toán
✅ **Chỉ khi trạng thái đơn hàng là `confirmed` trở lên, mới hiển thị bảng thanh toán.**

Các trạng thái hiển thị thanh toán:
- `confirmed` (Đã xác nhận)
- `shipping` (Đang giao hàng)  
- `delivered` (Đã giao hàng)

## Cấu trúc API

### 1. API lấy chi tiết đơn hàng
```
GET /API/orders/get_order_detail.php?order_id={order_id}
```

**Response:**
```json
{
  "success": true,
  "message": "Lấy chi tiết đơn hàng thành công",
  "data": {
    "id": 21,
    "user_id": 4,
    "username": "user",
    "email": "user@gmail.com",
    "phone": "0967586754",
    "address_line": "Ben tre",
    "city": "Mo cay",
    "province": "Ben Tre",
    "postal_code": "42",
    "order_date": "2025-06-28 07:12:20",
    "total_amount": 560000.00,
    "status": "shipping",
    "items": [...],
    "payments": [...]
  }
}
```

### 2. API cập nhật trạng thái đơn hàng
```
POST /API/orders/update_order.php
```

**Request:**
```json
{
  "order_id": 21,
  "status": "confirmed"
}
```

## Cấu trúc Flutter

### 1. Models
- `Payment` - Model cho thông tin thanh toán
- `OrderDetail` - Model mở rộng cho chi tiết đơn hàng
- `OrderItem` - Model cho sản phẩm trong đơn hàng

### 2. Screens
- `PaymentDashboardScreen` - Màn hình chính của Payment Dashboard

### 3. Tính năng UI
- **Danh sách đơn hàng** (1/3 màn hình)
  - Hiển thị danh sách tất cả đơn hàng
  - Màu sắc trạng thái khác nhau
  - Chọn đơn hàng để xem chi tiết

- **Chi tiết đơn hàng** (2/3 màn hình)
  - Thông tin khách hàng
  - Địa chỉ giao hàng
  - Thông tin đơn hàng
  - Dropdown cập nhật trạng thái
  - Danh sách sản phẩm
  - Lịch sử thanh toán (nếu có)

## Cách sử dụng

### 1. Truy cập Payment Dashboard
1. Đăng nhập vào Admin Panel
2. Chọn menu "Thanh toán" từ sidebar
3. Dashboard sẽ hiển thị danh sách đơn hàng

### 2. Xem chi tiết đơn hàng
1. Click vào một đơn hàng trong danh sách
2. Thông tin chi tiết sẽ hiển thị bên phải
3. Nếu đơn hàng có trạng thái `confirmed` trở lên, phần thanh toán sẽ hiển thị

### 3. Cập nhật trạng thái
1. Chọn đơn hàng cần cập nhật
2. Sử dụng dropdown "Trạng thái đơn hàng"
3. Trạng thái sẽ được cập nhật ngay lập tức

## Test API

### 1. Test Order Detail API
```bash
curl "http://127.0.0.1/EcommerceClothingApp/API/orders/get_order_detail.php?order_id=21"
```

### 2. Test với HTML
Mở file `API/test_payment_dashboard.html` trong trình duyệt để test các API.

## Database Schema

### Bảng liên quan:
- `orders` - Thông tin đơn hàng
- `users` - Thông tin khách hàng
- `user_addresses` - Địa chỉ giao hàng
- `order_items` - Sản phẩm trong đơn hàng
- `payments` - Thông tin thanh toán
- `products` - Thông tin sản phẩm
- `product_variant` - Biến thể sản phẩm
- `variants` - Biến thể
- `variant_attribute_values` - Giá trị thuộc tính biến thể
- `attribute_values` - Giá trị thuộc tính
- `attributes` - Thuộc tính (color, size, brand)

## Lưu ý

1. **Hiển thị thanh toán**: Chỉ hiển thị khi trạng thái đơn hàng là `confirmed`, `shipping`, hoặc `delivered`
2. **Cập nhật real-time**: Khi cập nhật trạng thái, thông tin sẽ được refresh ngay lập tức
3. **Xử lý lỗi**: Có thông báo lỗi và loading states
4. **Responsive**: Giao diện responsive cho desktop và mobile

## Tương lai

- Thêm tính năng xuất báo cáo thanh toán
- Thêm biểu đồ thống kê thanh toán
- Tích hợp với các cổng thanh toán thực tế
- Thêm tính năng refund/hoàn tiền 