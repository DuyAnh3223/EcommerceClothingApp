<?php
header('Content-Type: text/html; charset=utf-8');
require_once 'config/db_connect.php';

echo "<h1>🔍 Check Flutter Voucher Sending Issue</h1>";

// Check current voucher TEST2 status
echo "<h2>1. Current Voucher TEST2 Status</h2>";
$voucher_sql = "
    SELECT 
        v.id,
        v.voucher_code,
        v.discount_amount,
        v.quantity,
        (SELECT COUNT(*) FROM voucher_usage WHERE voucher_id = v.id) as used_count
    FROM vouchers v
    WHERE v.voucher_code = 'TEST2'
";

$voucher_result = mysqli_query($conn, $voucher_sql);

if ($voucher_result && mysqli_num_rows($voucher_result) > 0) {
    $voucher = mysqli_fetch_assoc($voucher_result);
    $remaining = $voucher['quantity'] - $voucher['used_count'];
    
    echo "<p><strong>Voucher ID:</strong> {$voucher['id']}</p>";
    echo "<p><strong>Code:</strong> {$voucher['voucher_code']}</p>";
    echo "<p><strong>Discount:</strong> " . number_format($voucher['discount_amount']) . " VNĐ</p>";
    echo "<p><strong>Total Quantity:</strong> {$voucher['quantity']}</p>";
    echo "<p><strong>Used Count:</strong> {$voucher['used_count']}</p>";
    echo "<p><strong>Remaining:</strong> $remaining</p>";
} else {
    echo "<p style='color: red;'>❌ Voucher TEST2 không tồn tại</p>";
}

// Check recent orders to see if voucher_id is being saved
echo "<h2>2. Check Recent Orders for Voucher Usage</h2>";
$recent_orders_sql = "
    SELECT 
        o.id,
        o.user_id,
        o.total_amount,
        o.voucher_id,
        o.created_at,
        v.voucher_code
    FROM orders o
    LEFT JOIN vouchers v ON o.voucher_id = v.id
    ORDER BY o.created_at DESC
    LIMIT 10
";

$recent_orders_result = mysqli_query($conn, $recent_orders_sql);

if ($recent_orders_result && mysqli_num_rows($recent_orders_result) > 0) {
    echo "<p><strong>Recent orders:</strong></p>";
    echo "<table border='1' style='border-collapse: collapse; width: 100%;'>";
    echo "<tr><th>Order ID</th><th>User ID</th><th>Total Amount</th><th>Voucher ID</th><th>Voucher Code</th><th>Created At</th></tr>";
    
    while ($order = mysqli_fetch_assoc($recent_orders_result)) {
        $voucher_code = $order['voucher_code'] ?? 'NULL';
        $voucher_id = $order['voucher_id'] ?? 'NULL';
        
        echo "<tr>";
        echo "<td>{$order['id']}</td>";
        echo "<td>{$order['user_id']}</td>";
        echo "<td>" . number_format($order['total_amount']) . " VNĐ</td>";
        echo "<td>$voucher_id</td>";
        echo "<td>$voucher_code</td>";
        echo "<td>{$order['created_at']}</td>";
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "<p style='color: orange;'>⚠️ No recent orders found</p>";
}

// Check voucher usage records
echo "<h2>3. Check Voucher Usage Records</h2>";
$usage_sql = "
    SELECT 
        vu.id,
        vu.voucher_id,
        vu.user_id,
        vu.order_id,
        vu.discount_applied,
        vu.used_at,
        v.voucher_code
    FROM voucher_usage vu
    JOIN vouchers v ON vu.voucher_id = v.id
    ORDER BY vu.used_at DESC
    LIMIT 10
";

$usage_result = mysqli_query($conn, $usage_sql);

if ($usage_result && mysqli_num_rows($usage_result) > 0) {
    echo "<p><strong>Recent voucher usage records:</strong></p>";
    echo "<table border='1' style='border-collapse: collapse; width: 100%;'>";
    echo "<tr><th>ID</th><th>Voucher ID</th><th>Voucher Code</th><th>User ID</th><th>Order ID</th><th>Discount</th><th>Used At</th></tr>";
    
    while ($usage = mysqli_fetch_assoc($usage_result)) {
        echo "<tr>";
        echo "<td>{$usage['id']}</td>";
        echo "<td>{$usage['voucher_id']}</td>";
        echo "<td>{$usage['voucher_code']}</td>";
        echo "<td>{$usage['user_id']}</td>";
        echo "<td>{$usage['order_id']}</td>";
        echo "<td>" . number_format($usage['discount_applied']) . " VNĐ</td>";
        echo "<td>{$usage['used_at']}</td>";
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "<p style='color: orange;'>⚠️ No voucher usage records found</p>";
}

// Test different scenarios
echo "<h2>4. Test Different Voucher Scenarios</h2>";

// Scenario 1: No voucher
echo "<h3>Scenario 1: Order without voucher</h3>";
$no_voucher_request = [
    'user_id' => 4,
    'address_id' => 3,
    'payment_method' => 'COD',
    'cart_items' => [
        [
            'type' => 'product',
            'product_id' => 4,
            'variant_id' => 6,
            'quantity' => 1
        ]
    ]
    // No voucher data
];

echo "<p><strong>Request without voucher:</strong></p>";
echo "<pre>" . json_encode($no_voucher_request, JSON_PRETTY_PRINT) . "</pre>";

$voucher_id_scenario1 = isset($no_voucher_request['voucher_id']) ? (int)$no_voucher_request['voucher_id'] : null;
echo "<p><strong>Parsed voucher_id:</strong> $voucher_id_scenario1</p>";

// Scenario 2: With voucher TEST2
echo "<h3>Scenario 2: Order with voucher TEST2</h3>";
$with_voucher_request = [
    'user_id' => 4,
    'address_id' => 3,
    'payment_method' => 'COD',
    'cart_items' => [
        [
            'type' => 'product',
            'product_id' => 4,
            'variant_id' => 6,
            'quantity' => 1
        ]
    ],
    'voucher_id' => 10, // TEST2
    'voucher_code' => 'TEST2',
    'discount_amount' => 5000
];

echo "<p><strong>Request with voucher:</strong></p>";
echo "<pre>" . json_encode($with_voucher_request, JSON_PRETTY_PRINT) . "</pre>";

$voucher_id_scenario2 = isset($with_voucher_request['voucher_id']) ? (int)$with_voucher_request['voucher_id'] : null;
echo "<p><strong>Parsed voucher_id:</strong> $voucher_id_scenario2</p>";

// Scenario 3: Voucher as string
echo "<h3>Scenario 3: Voucher ID as string</h3>";
$string_voucher_request = [
    'user_id' => 4,
    'address_id' => 3,
    'payment_method' => 'COD',
    'cart_items' => [
        [
            'type' => 'product',
            'product_id' => 4,
            'variant_id' => 6,
            'quantity' => 1
        ]
    ],
    'voucher_id' => '10', // String instead of int
    'voucher_code' => 'TEST2',
    'discount_amount' => 5000
];

echo "<p><strong>Request with string voucher_id:</strong></p>";
echo "<pre>" . json_encode($string_voucher_request, JSON_PRETTY_PRINT) . "</pre>";

$voucher_id_scenario3 = isset($string_voucher_request['voucher_id']) ? (int)$string_voucher_request['voucher_id'] : null;
echo "<p><strong>Parsed voucher_id:</strong> $voucher_id_scenario3</p>";

// Check if Flutter might be sending voucher data in different format
echo "<h2>5. Possible Flutter Issues</h2>";
echo "<p><strong>Common issues when Flutter sends voucher data:</strong></p>";
echo "<ul>";
echo "<li><strong>Missing voucher_id:</strong> Flutter might not be sending voucher_id field</li>";
echo "<li><strong>Wrong data type:</strong> voucher_id might be sent as string instead of int</li>";
echo "<li><strong>Wrong field name:</strong> Flutter might use different field names</li>";
echo "<li><strong>Null values:</strong> voucher_id might be null or empty</li>";
echo "<li><strong>Wrong voucher_id:</strong> Flutter might be sending wrong voucher_id</li>";
echo "</ul>";

echo "<h3>Debug Steps for Flutter:</h3>";
echo "<ol>";
echo "<li>Check Flutter logs to see what voucher data is being sent</li>";
echo "<li>Verify voucher_id is being included in the request</li>";
echo "<li>Check if voucher_id is the correct value (should be 10 for TEST2)</li>";
echo "<li>Verify discount_amount is being sent correctly</li>";
echo "<li>Check if voucher_code is being sent</li>";
echo "</ol>";

echo "<h3>Debug Steps for Backend:</h3>";
echo "<ol>";
echo "<li>Check error logs for voucher processing</li>";
echo "<li>Verify voucher validation is working</li>";
echo "<li>Check if voucher usage is being recorded</li>";
echo "<li>Verify order creation with voucher_id</li>";
echo "</ol>";

mysqli_close($conn);
?> 