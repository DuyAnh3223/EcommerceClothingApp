<?php
header('Content-Type: text/html; charset=utf-8');
require_once 'config/db_connect.php';

echo "<h1>🔍 Debug Flutter Voucher Issue</h1>";

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

// Simulate Flutter request with potential issues
echo "<h2>2. Simulate Flutter Request Issues</h2>";

$flutter_requests = [
    [
        'name' => 'Correct Flutter Request',
        'data' => [
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
            'voucher_id' => 10,
            'voucher_code' => 'TEST2',
            'discount_amount' => 5000
        ]
    ],
    [
        'name' => 'Flutter Request Missing voucher_id',
        'data' => [
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
            'voucher_code' => 'TEST2',
            'discount_amount' => 5000
        ]
    ],
    [
        'name' => 'Flutter Request with String voucher_id',
        'data' => [
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
            'voucher_id' => '10',
            'voucher_code' => 'TEST2',
            'discount_amount' => 5000
        ]
    ],
    [
        'name' => 'Flutter Request with Null voucher_id',
        'data' => [
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
            'voucher_id' => null,
            'voucher_code' => 'TEST2',
            'discount_amount' => 5000
        ]
    ]
];

foreach ($flutter_requests as $index => $request) {
    echo "<h3>" . ($index + 1) . ". " . $request['name'] . "</h3>";
    
    $input = $request['data'];
    
    // Parse like the API does
    $voucher_id = isset($input['voucher_id']) ? (int)$input['voucher_id'] : null;
    $voucher_code = isset($input['voucher_code']) ? $input['voucher_code'] : null;
    $discount_amount = isset($input['discount_amount']) ? (float)$input['discount_amount'] : 0.0;
    
    echo "<p><strong>Raw input:</strong></p>";
    echo "<pre>" . json_encode($input, JSON_PRETTY_PRINT) . "</pre>";
    
    echo "<p><strong>Parsed data:</strong></p>";
    echo "<p>voucher_id: " . ($voucher_id ?? 'NULL') . "</p>";
    echo "<p>voucher_code: " . ($voucher_code ?? 'NULL') . "</p>";
    echo "<p>discount_amount: $discount_amount</p>";
    
    // Test voucher validation
    if ($voucher_id && $discount_amount > 0) {
        $voucher_sql = "SELECT id, voucher_code, discount_amount, quantity, 
                               (SELECT COUNT(*) FROM voucher_usage WHERE voucher_id = vouchers.id) as used_count
                        FROM vouchers WHERE id = ?";
        $voucher_stmt = $conn->prepare($voucher_sql);
        $voucher_stmt->bind_param("i", $voucher_id);
        $voucher_stmt->execute();
        $voucher_result = $voucher_stmt->get_result();
        
        if ($voucher_result->num_rows > 0) {
            $voucher_data = $voucher_result->fetch_assoc();
            $remaining_quantity = $voucher_data['quantity'] - $voucher_data['used_count'];
            
            echo "<p style='color: green;'><strong>✅ Voucher found:</strong> code={$voucher_data['voucher_code']}, remaining=$remaining_quantity</p>";
            
            if ($remaining_quantity > 0) {
                echo "<p style='color: green;'><strong>✅ Voucher can be applied</strong></p>";
            } else {
                echo "<p style='color: red;'><strong>❌ Voucher has no remaining quantity</strong></p>";
            }
        } else {
            echo "<p style='color: red;'><strong>❌ Voucher not found</strong></p>";
        }
        $voucher_stmt->close();
    } else {
        if (!$voucher_id) {
            echo "<p style='color: orange;'><strong>⚠️ No voucher_id provided</strong></p>";
        }
        if ($discount_amount <= 0) {
            echo "<p style='color: orange;'><strong>⚠️ Invalid discount_amount</strong></p>";
        }
    }
    
    echo "<hr>";
}

// Check recent orders to see if voucher_id is being saved
echo "<h2>3. Check Recent Orders for Voucher Usage</h2>";
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
echo "<h2>4. Check Voucher Usage Records</h2>";
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

echo "<h2>5. Debug Recommendations</h2>";
echo "<h3>For Flutter App:</h3>";
echo "<ol>";
echo "<li><strong>Check Flutter logs:</strong> Add print statements to see what voucher data is being sent</li>";
echo "<li><strong>Verify voucher_id:</strong> Make sure voucher_id = 10 is being sent for TEST2</li>";
echo "<li><strong>Check data types:</strong> Ensure voucher_id is sent as integer, not string</li>";
echo "<li><strong>Verify discount_amount:</strong> Make sure it's greater than 0</li>";
echo "<li><strong>Test with different voucher:</strong> Try with a different voucher to see if the issue persists</li>";
echo "</ol>";

echo "<h3>For Backend API:</h3>";
echo "<ol>";
echo "<li><strong>Check error logs:</strong> Look for any errors in the API logs</li>";
echo "<li><strong>Enable debug logs:</strong> The API now has debug logs added</li>";
echo "<li><strong>Test with Postman:</strong> Try making a request with voucher data manually</li>";
echo "<li><strong>Check database:</strong> Verify voucher usage records are being created</li>";
echo "</ol>";

echo "<h3>Next Steps:</h3>";
echo "<ol>";
echo "<li>Run the Flutter app and check the logs when placing an order with voucher TEST2</li>";
echo "<li>Check the API error logs for any voucher-related errors</li>";
echo "<li>Test the API manually with the test scripts created</li>";
echo "<li>Verify that voucher_id is being sent correctly from Flutter</li>";
echo "</ol>";

mysqli_close($conn);
?> 