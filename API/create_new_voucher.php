<?php
require_once 'config/db_connect.php';

// Create a new valid voucher for 2025
$voucherCode = 'AGENCY2025';
$discountAmount = 50000;
$quantity = 100;
$startDate = '2025-01-01 00:00:00';
$endDate = '2025-12-31 23:59:59';

$query = "INSERT INTO vouchers (voucher_code, discount_amount, quantity, start_date, end_date, voucher_type) 
          VALUES (?, ?, ?, ?, ?, 'all_products')";

$stmt = mysqli_prepare($conn, $query);
mysqli_stmt_bind_param($stmt, 'sdisss', $voucherCode, $discountAmount, $quantity, $startDate, $endDate);

if (mysqli_stmt_execute($stmt)) {
    echo "✅ Voucher created successfully!\n";
    echo "Code: $voucherCode\n";
    echo "Discount: $discountAmount VNĐ\n";
    echo "Quantity: $quantity\n";
    echo "Valid from: $startDate to $endDate\n";
} else {
    echo "❌ Error creating voucher: " . mysqli_error($conn) . "\n";
}

mysqli_stmt_close($stmt);
mysqli_close($conn);
?> 