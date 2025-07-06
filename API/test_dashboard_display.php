<?php
// Test script để kiểm tra logic hiển thị dashboard
require_once 'config/db_connect.php';

echo "=== Test Dashboard Display Logic ===\n\n";

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
        p.transaction_code,
        p.paid_at
    FROM orders o
    LEFT JOIN payments p ON o.id = p.order_id
    WHERE p.status = 'paid'
    ORDER BY o.id DESC
    LIMIT 5
";

$result = $conn->query($query);

if ($result->num_rows > 0) {
    echo "Recent paid orders with display logic:\n";
    echo str_repeat("-", 100) . "\n";
    
    while ($row = $result->fetch_assoc()) {
        echo "Order #{$row['id']}\n";
        echo "Payment Method: {$row['payment_method']}\n";
        echo "Order total_amount: {$row['total_amount']} VNĐ\n";
        echo "Order total_amount_bacoin: {$row['total_amount_bacoin']} BACoin\n";
        echo "Payment amount: {$row['amount']} VNĐ\n";
        echo "Payment amount_bacoin: {$row['amount_bacoin']} BACoin\n";
        
        // Simulate dashboard display logic
        if ($row['payment_method'] == 'BACoin') {
            echo "Dashboard Display:\n";
            echo "  - Tổng tiền: {$row['amount_bacoin']} BACoin\n";
            echo "  - Chi tiết thanh toán:\n";
            echo "    + Số tiền (VNĐ): {$row['amount']} VNĐ\n";
            echo "    + Số tiền (BACoin): {$row['amount_bacoin']} BACoin\n";
        } else {
            echo "Dashboard Display:\n";
            echo "  - Tổng tiền: {$row['amount']} VNĐ\n";
            echo "  - Chi tiết thanh toán:\n";
            echo "    + Số tiền: {$row['amount']} VNĐ\n";
        }
        
        echo str_repeat("-", 50) . "\n";
    }
} else {
    echo "No paid orders found.\n";
}

// Test 2: Payment method distribution
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

// Test 3: Check dashboard totals calculation
echo "\n=== Dashboard Totals Calculation ===\n";
$totals_query = "
    SELECT 
        SUM(CASE WHEN payment_method = 'BACoin' THEN amount_bacoin ELSE 0 END) as total_bacoin,
        SUM(CASE WHEN payment_method != 'BACoin' THEN amount ELSE 0 END) as total_vnd,
        COUNT(*) as total_orders
    FROM payments 
    WHERE status = 'paid'
";

$totals_result = $conn->query($totals_query);
if ($totals_result->num_rows > 0) {
    $totals = $totals_result->fetch_assoc();
    echo "Dashboard Summary:\n";
    echo "Total VNĐ: {$totals['total_vnd']} VNĐ\n";
    echo "Total BACoin: {$totals['total_bacoin']} BACoin\n";
    echo "Total Orders: {$totals['total_orders']} đơn\n";
}

echo "\n=== Test Complete ===\n";
?> 