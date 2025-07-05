<?php
require_once 'config/db_connect.php';

// Tạo voucher test có hiệu lực
$voucherCode = 'TEST2025';
$discountAmount = 50000;
$quantity = 100;
$startDate = '2025-01-01 00:00:00';
$endDate = '2025-12-31 23:59:59';
$voucherType = 'all_products';

// Kiểm tra xem voucher đã tồn tại chưa
$checkQuery = "SELECT id FROM vouchers WHERE voucher_code = '$voucherCode'";
$checkResult = mysqli_query($conn, $checkQuery);

if (mysqli_num_rows($checkResult) > 0) {
    echo "Voucher $voucherCode đã tồn tại!\n";
} else {
    // Thêm voucher mới
    $insertQuery = "INSERT INTO vouchers (voucher_code, discount_amount, quantity, start_date, end_date, voucher_type, created_at, updated_at) 
                    VALUES ('$voucherCode', $discountAmount, $quantity, '$startDate', '$endDate', '$voucherType', NOW(), NOW())";
    
    if (mysqli_query($conn, $insertQuery)) {
        echo "✅ Đã tạo voucher thành công!\n";
        echo "Mã voucher: $voucherCode\n";
        echo "Giảm giá: " . number_format($discountAmount) . " VNĐ\n";
        echo "Số lượng: $quantity\n";
        echo "Hiệu lực từ: $startDate đến $endDate\n";
    } else {
        echo "❌ Lỗi tạo voucher: " . mysqli_error($conn) . "\n";
    }
}

mysqli_close($conn);
?> 