<?php
// Test script để kiểm tra hiển thị giá trị thanh toán theo phương thức
require_once 'config/db_connect.php';

echo "=== Test Payment Display Logic ===\n\n";

// Test 1: Get orders with payments (including all payment methods)
$query = "
    SELECT 
        o.id,
        o.total_amount,
        o.total_amount_bacoin,
        p.payment_method,
        p.amount,
        p.amount_bacoin,
        p.status
    FROM orders o
    LEFT JOIN payments p ON o.id = p.order_id
    WHERE p.status = 'paid'
    ORDER BY o.id DESC
    LIMIT 10
";

$result = $conn->query($query);

if ($result->num_rows > 0) {
    echo "Recent paid orders:\n";
    echo str_repeat("-", 80) . "\n";
    
    while ($row = $result->fetch_assoc()) {
        echo "Order #{$row['id']}\n";
        echo "Payment Method: {$row['payment_method']}\n";
        echo "Order total_amount: {$row['total_amount']} VNĐ\n";
        echo "Order total_amount_bacoin: {$row['total_amount_bacoin']} BACoin\n";
        echo "Payment amount: {$row['amount']} VNĐ\n";
        echo "Payment amount_bacoin: {$row['amount_bacoin']} BACoin\n";
        
        // Simulate the display logic
        if ($row['payment_method'] == 'BACoin') {
            $display_amount = $row['amount_bacoin'] . " BACoin";
        } else {
            $display_amount = $row['amount'] . " VNĐ";
        }
        
        echo "Display Amount: {$display_amount}\n";
        echo str_repeat("-", 40) . "\n";
    }
} else {
    echo "No paid orders found.\n";
}

// Test 2: Check payment method distribution
echo "\n=== Payment Method Distribution ===\n";
$method_query = "
    SELECT 
        payment_method,
        COUNT(*) as count,
        SUM(amount) as total_vnd,
        SUM(amount_bacoin) as total_bacoin
    FROM payments 
    WHERE status = 'paid'
    GROUP BY payment_method
    ORDER BY count DESC
";

$method_result = $conn->query($method_query);

if ($method_result->num_rows > 0) {
    while ($row = $method_result->fetch_assoc()) {
        echo "Method: {$row['payment_method']}\n";
        echo "Count: {$row['count']}\n";
        echo "Total VNĐ: {$row['total_vnd']}\n";
        echo "Total BACoin: {$row['total_bacoin']}\n";
        echo str_repeat("-", 30) . "\n";
    }
}

// Test 3: Check if there are any COD/VNPAY payments
echo "\n=== Checking for COD/VNPAY payments ===\n";
$cod_vnpay_query = "
    SELECT 
        o.id,
        p.payment_method,
        p.amount,
        p.amount_bacoin
    FROM orders o
    JOIN payments p ON o.id = p.order_id
    WHERE p.status = 'paid' 
    AND p.payment_method IN ('COD', 'VNPAY')
    ORDER BY o.id DESC
    LIMIT 5
";

$cod_vnpay_result = $conn->query($cod_vnpay_query);

if ($cod_vnpay_result->num_rows > 0) {
    echo "Found COD/VNPAY payments:\n";
    while ($row = $cod_vnpay_result->fetch_assoc()) {
        echo "Order #{$row['id']} - {$row['payment_method']}: {$row['amount']} VNĐ\n";
    }
} else {
    echo "No COD/VNPAY payments found in recent orders.\n";
}

echo "\n=== Test Complete ===\n";
?> 