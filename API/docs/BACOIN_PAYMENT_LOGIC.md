# BACoin Payment Logic

## Tổng quan

Hệ thống thanh toán BACoin có logic khác biệt với các phương thức thanh toán khác (COD, VNPAY):

## Logic thanh toán BACoin

### 1. Khi thanh toán bằng BACoin:
- **total_amount** = 0 (không lưu tiền VND)
- **total_amount_bacoin** = Tổng tiền BACoin (bao gồm cả phí sàn)
- **platform_fee** = 0 (phí sàn được tính trực tiếp vào total_amount_bacoin)

### 2. Khi thanh toán bằng COD/VNPAY:
- **total_amount** = Tổng tiền VND (bao gồm cả phí sàn)
- **total_amount_bacoin** = NULL
- **platform_fee** = Phí sàn (để tính toán cho agency)

## Phân bổ BACoin

### Sản phẩm của Agency:
- **Agency nhận**: Giá gốc sản phẩm
- **Admin nhận**: Phí sàn (20%)

### Sản phẩm của Admin:
- **Admin nhận**: 100% giá trị

## Ví dụ

### Sản phẩm Agency (giá gốc: 50,000 BACoin, phí sàn: 20%)

#### Thanh toán bằng BACoin:
- User trả: 60,000 BACoin
- Agency nhận: 50,000 BACoin (giá gốc)
- Admin nhận: 10,000 BACoin (phí sàn)
- Database: `total_amount = 0`, `total_amount_bacoin = 60000`, `platform_fee = 0`

#### Thanh toán bằng COD:
- User trả: 60,000 VND
- Agency nhận: 50,000 VND (giá gốc)
- Admin nhận: 10,000 VND (phí sàn)
- Database: `total_amount = 60000`, `total_amount_bacoin = NULL`, `platform_fee = 10000`

## Cấu trúc Database

### Bảng `orders`:
```sql
total_amount DECIMAL(15,2) -- Tiền VND (0 cho BACoin)
total_amount_bacoin DECIMAL(15,2) -- Tiền BACoin (NULL cho VND)
platform_fee DECIMAL(15,2) -- Phí sàn (0 cho BACoin)
```

### Bảng `payments`:
```sql
payment_method ENUM('COD','Bank','Momo','VNPAY','Other','BACoin')
amount DECIMAL(15,2) -- Số tiền VND
amount_bacoin DECIMAL(15,2) -- Số tiền BACoin
```

## API Response

### BACoin Payment Success:
```json
{
  "success": true,
  "message": "Đặt hàng thành công! Đã trừ 60000 BACoin từ tài khoản. Đơn hàng đã được xác nhận.",
  "order_id": 155,
  "payment_method": "BACoin",
  "requires_payment": false,
  "order_status": "confirmed",
  "new_balance": 2826668,
  "amount_deducted": 60000,
  "transaction_code": "BACOIN2025070507134646629934",
  "bacoin_distribution": {
    "admin_received": 10000,
    "agency_received": 50000,
    "total_distributed": 60000
  }
}
```

## Lưu ý quan trọng

1. **Phí sàn chỉ áp dụng cho COD/VNPAY**: Khi thanh toán bằng BACoin, phí sàn được tính trực tiếp vào `total_amount_bacoin`

2. **Phân bổ tự động**: Hệ thống tự động phân bổ BACoin cho agency và admin dựa trên loại sản phẩm

3. **Kiểm tra số dư**: Hệ thống kiểm tra số dư BACoin trước khi cho phép thanh toán

4. **Ghi nhận giao dịch**: Tất cả giao dịch BACoin được ghi nhận trong bảng `bacoin_transactions`