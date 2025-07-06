<?php
// Test script để kiểm tra tính nhất quán của hiển thị giá trị thanh toán
require_once 'config/db_connect.php';

echo "=== Test Payment Display Consistency ===\n\n";

// Test 1: Get recent orders with payments
$query = "
    SELECT 
        o.id,
        o.total_amount,
        o.total_amount_bacoin,
        p.payment_method,
        p.amount,
        p.amount_bacoin,
        p.status,
        p.transaction_code
    FROM orders o
    LEFT JOIN payments p ON o.id = p.order_id
    WHERE p.status = 'paid'
    ORDER BY o.id DESC
    LIMIT 10
";

$result = $conn->query($query);

if ($result->num_rows > 0) {
    echo "Recent paid orders with display logic:\n";
    echo str_repeat("-", 100) . "\n";
    
    while ($row = $result->fetch_assoc()) {
        echo "Order #{$row['id']}\n";
        echo "Payment Method: {$row['payment_method']}\n";
        echo "Transaction Code: {$row['transaction_code']}\n";
        
        // Simulate the display logic for order total
        if ($row['payment_method'] == 'BACoin') {
            $order_display = $row['amount_bacoin'] . " BACoin";
        } else {
            $order_display = $row['amount'] . " VNĐ";
        }
        
        // Simulate the display logic for payment detail
        if ($row['payment_method'] == 'BACoin') {
            $payment_display = $row['amount_bacoin'] . " BACoin";
        } else {
            $payment_display = $row['amount'] . " VNĐ";
        }
        
        echo "Order Total Display: {$order_display}\n";
        echo "Payment Detail Display: {$payment_display}\n";
        echo "Consistent: " . ($order_display == $payment_display ? "✅ YES" : "❌ NO") . "\n";
        echo str_repeat("-", 50) . "\n";
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
        
        if ($row['payment_method'] == 'BACoin') {
            echo "Total Amount: {$row['total_bacoin']} BACoin\n";
        } else {
            echo "Total Amount: {$row['total_vnd']} VNĐ\n";
        }
        echo str_repeat("-", 30) . "\n";
    }
}

// Test 3: Verify BACoin payments have amount_bacoin
echo "\n=== BACoin Payment Verification ===\n";
$bacoin_query = "
    SELECT 
        order_id,
        amount,
        amount_bacoin,
        CASE 
            WHEN amount_bacoin IS NOT NULL AND amount_bacoin > 0 THEN 'Valid'
            ELSE 'Invalid'
        END as validation
    FROM payments 
    WHERE payment_method = 'BACoin' AND status = 'paid'
    ORDER BY order_id DESC
    LIMIT 5
";

$bacoin_result = $conn->query($bacoin_query);

if ($bacoin_result->num_rows > 0) {
    echo "BACoin payments validation:\n";
    while ($row = $bacoin_result->fetch_assoc()) {
        echo "Order #{$row['order_id']}: {$row['amount_bacoin']} BACoin ({$row['validation']})\n";
    }
} else {
    echo "No BACoin payments found.\n";
}

echo "\n=== Test Complete ===\n";
?> 