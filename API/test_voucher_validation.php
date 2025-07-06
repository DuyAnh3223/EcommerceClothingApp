<?php
include_once 'config/db_connect.php';

echo "=== Testing Voucher Validation API ===\n";

// Test both vouchers
$test_vouchers = ['TEST2', 'GIAM20K'];

foreach ($test_vouchers as $voucher_code) {
    echo "\n--- Testing Voucher: $voucher_code ---\n";
    
    $product_ids = [4]; // Test with product ID 4

    // Get voucher details using the same logic as the API
    $voucherQuery = "
        SELECT 
            v.id,
            v.voucher_code,
            v.discount_amount,
            v.quantity,
            v.start_date,
            v.end_date,
            v.voucher_type,
            v.category_filter,
            v.status
        FROM vouchers v
        WHERE v.voucher_code = '$voucher_code'
    ";

    $voucherResult = mysqli_query($conn, $voucherQuery);

    if (!$voucherResult || mysqli_num_rows($voucherResult) === 0) {
        echo "✗ Voucher not found\n";
        continue;
    }

    $voucher = mysqli_fetch_assoc($voucherResult);

    echo "Voucher details:\n";
    echo json_encode($voucher, JSON_PRETTY_PRINT) . "\n";

    // Check if voucher is valid using the same logic as the API
    $now = new DateTime();
    $startDate = new DateTime($voucher['start_date']);
    $endDate = new DateTime($voucher['end_date']);

    echo "\nValidation checks:\n";
    echo "Current time: " . $now->format('Y-m-d H:i:s') . "\n";
    echo "Start date: " . $startDate->format('Y-m-d H:i:s') . "\n";
    echo "End date: " . $endDate->format('Y-m-d H:i:s') . "\n";
    echo "Status: " . $voucher['status'] . "\n";
    echo "Quantity: " . $voucher['quantity'] . "\n";

    // Check voucher validity period
    if ($now < $startDate) {
        echo "✗ Voucher chưa có hiệu lực\n";
        continue;
    }

    if ($now > $endDate) {
        echo "✗ Voucher đã hết hiệu lực\n";
        continue;
    }

    // Check voucher status and quantity using new logic
    if ($voucher['status'] !== 'active') {
        if ($voucher['status'] === 'inactive') {
            echo "✗ Voucher đã hết số lượng sử dụng\n";
        } elseif ($voucher['status'] === 'expired') {
            echo "✗ Voucher đã hết hiệu lực\n";
        } else {
            echo "✗ Voucher không hợp lệ\n";
        }
        continue;
    }

    if ($voucher['quantity'] <= 0) {
        echo "✗ Voucher đã hết số lượng sử dụng\n";
        continue;
    }

    echo "✓ Voucher is valid!\n";

    // Calculate discount for all products
    $applicableProducts = $product_ids;
    $totalDiscount = $voucher['discount_amount'] * count($applicableProducts);

    echo "\nValidation result:\n";
    $result = [
        'voucher_id' => (int)$voucher['id'],
        'voucher_code' => $voucher['voucher_code'],
        'discount_amount' => (float)$voucher['discount_amount'],
        'total_discount' => $totalDiscount,
        'applicable_products' => $applicableProducts,
        'remaining_quantity' => (int)$voucher['quantity'],
        'voucher_type' => $voucher['voucher_type'],
        'category_filter' => $voucher['category_filter']
    ];

    echo json_encode($result, JSON_PRETTY_PRINT) . "\n";
    
    // Check data types
    echo "\nData type check:\n";
    echo "remaining_quantity type: " . gettype($result['remaining_quantity']) . "\n";
    echo "discount_amount type: " . gettype($result['discount_amount']) . "\n";
    echo "voucher_id type: " . gettype($result['voucher_id']) . "\n";
}

$conn->close();
?> 