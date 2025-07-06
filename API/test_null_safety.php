<?php
require_once 'config/db_connect.php';

echo "=== Test Null Safety in Payment Data ===\n\n";

// Test 1: Check for null values in payments table
$query = "
    SELECT 
        id,
        order_id,
        payment_method,
        amount,
        amount_bacoin,
        status,
        transaction_code,
        paid_at
    FROM payments 
    WHERE status = 'paid'
    ORDER BY id DESC
    LIMIT 10
";

$result = $conn->query($query);

if ($result->num_rows > 0) {
    echo "Recent payments with null check:\n";
    echo str_repeat("-", 80) . "\n";
    
    while ($row = $result->fetch_assoc()) {
        echo "Payment ID: {$row['id']}\n";
        echo "Order ID: {$row['order_id']}\n";
        echo "Payment Method: " . ($row['payment_method'] ?? 'NULL') . "\n";
        echo "Amount: " . ($row['amount'] ?? 'NULL') . "\n";
        echo "Amount BACoin: " . ($row['amount_bacoin'] ?? 'NULL') . "\n";
        echo "Status: " . ($row['status'] ?? 'NULL') . "\n";
        echo "Transaction Code: " . ($row['transaction_code'] ?? 'NULL') . "\n";
        echo "Paid At: " . ($row['paid_at'] ?? 'NULL') . "\n";
        
        // Check for potential null issues
        $issues = [];
        if ($row['payment_method'] === null) $issues[] = "payment_method is NULL";
        if ($row['amount'] === null) $issues[] = "amount is NULL";
        if ($row['amount_bacoin'] === null) $issues[] = "amount_bacoin is NULL";
        if ($row['status'] === null) $issues[] = "status is NULL";
        
        if (!empty($issues)) {
            echo "⚠️  POTENTIAL NULL ISSUES: " . implode(", ", $issues) . "\n";
        } else {
            echo "✅ No null issues found\n";
        }
        echo str_repeat("-", 40) . "\n";
    }
} else {
    echo "No paid payments found.\n";
}

// Test 2: Check orders with payments
echo "\n=== Orders with Payment Data ===\n";
$order_query = "
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
    LIMIT 5
";

$order_result = $conn->query($order_query);

if ($order_result->num_rows > 0) {
    while ($row = $order_result->fetch_assoc()) {
        echo "Order #{$row['id']}\n";
        echo "Payment Method: " . ($row['payment_method'] ?? 'NULL') . "\n";
        echo "Order total_amount: " . ($row['total_amount'] ?? 'NULL') . "\n";
        echo "Order total_amount_bacoin: " . ($row['total_amount_bacoin'] ?? 'NULL') . "\n";
        echo "Payment amount: " . ($row['amount'] ?? 'NULL') . "\n";
        echo "Payment amount_bacoin: " . ($row['amount_bacoin'] ?? 'NULL') . "\n";
        
        // Simulate Flutter display logic
        $method = $row['payment_method'] ?? 'Unknown';
        if ($method == 'BACoin') {
            $display_amount = ($row['amount_bacoin'] ?? 0) . " BACoin";
        } else {
            $display_amount = ($row['amount'] ?? 0) . " VNĐ";
        }
        echo "Display Amount: {$display_amount}\n";
        echo str_repeat("-", 30) . "\n";
    }
}

echo "\n=== Test Complete ===\n";
?> 