<?php
header('Content-Type: text/html; charset=utf-8');
require_once 'config/db_connect.php';

echo "<h1>🔍 Debug Voucher TEST2 Issue</h1>";

// 1. Kiểm tra voucher TEST2 hiện tại
echo "<h2>1. Check Voucher TEST2 Current Status</h2>";
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

// 2. Kiểm tra voucher usage records cho TEST2
echo "<h2>2. Check Voucher Usage Records for TEST2</h2>";
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
    WHERE v.voucher_code = 'TEST2'
    ORDER BY vu.used_at DESC
";

$usage_result = mysqli_query($conn, $usage_sql);

if ($usage_result && mysqli_num_rows($usage_result) > 0) {
    echo "<p><strong>Found " . mysqli_num_rows($usage_result) . " usage records:</strong></p>";
    echo "<table border='1' style='border-collapse: collapse; width: 100%;'>";
    echo "<tr><th>ID</th><th>Voucher ID</th><th>User ID</th><th>Order ID</th><th>Discount</th><th>Used At</th></tr>";
    
    while ($usage = mysqli_fetch_assoc($usage_result)) {
        echo "<tr>";
        echo "<td>{$usage['id']}</td>";
        echo "<td>{$usage['voucher_id']}</td>";
        echo "<td>{$usage['user_id']}</td>";
        echo "<td>{$usage['order_id']}</td>";
        echo "<td>" . number_format($usage['discount_applied']) . " VNĐ</td>";
        echo "<td>{$usage['used_at']}</td>";
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "<p style='color: orange;'>⚠️ Không có usage records cho voucher TEST2</p>";
}

// 3. Kiểm tra orders gần đây có sử dụng voucher TEST2
echo "<h2>3. Check Recent Orders with TEST2 Voucher</h2>";
$orders_sql = "
    SELECT 
        o.id,
        o.user_id,
        o.total_amount,
        o.voucher_id,
        o.created_at,
        v.voucher_code
    FROM orders o
    LEFT JOIN vouchers v ON o.voucher_id = v.id
    WHERE v.voucher_code = 'TEST2'
    ORDER BY o.created_at DESC
    LIMIT 10
";

$orders_result = mysqli_query($conn, $orders_sql);

if ($orders_result && mysqli_num_rows($orders_result) > 0) {
    echo "<p><strong>Found " . mysqli_num_rows($orders_result) . " orders with TEST2 voucher:</strong></p>";
    echo "<table border='1' style='border-collapse: collapse; width: 100%;'>";
    echo "<tr><th>Order ID</th><th>User ID</th><th>Total Amount</th><th>Voucher ID</th><th>Created At</th></tr>";
    
    while ($order = mysqli_fetch_assoc($orders_result)) {
        echo "<tr>";
        echo "<td>{$order['id']}</td>";
        echo "<td>{$order['user_id']}</td>";
        echo "<td>" . number_format($order['total_amount']) . " VNĐ</td>";
        echo "<td>{$order['voucher_id']}</td>";
        echo "<td>{$order['created_at']}</td>";
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "<p style='color: orange;'>⚠️ Không có orders nào sử dụng voucher TEST2</p>";
}

// 4. Test tạo order với voucher TEST2
echo "<h2>4. Test Create Order with TEST2 Voucher</h2>";

$test_user_id = 4;
$test_address_id = 3;
$test_voucher_id = 10; // TEST2
$test_discount_amount = 5000;
$test_total_amount = 100000;
$test_final_total = $test_total_amount - $test_discount_amount;

echo "<p><strong>Test Data:</strong></p>";
echo "<p>User ID: $test_user_id</p>";
echo "<p>Address ID: $test_address_id</p>";
echo "<p>Voucher ID: $test_voucher_id</p>";
echo "<p>Original Total: " . number_format($test_total_amount) . " VNĐ</p>";
echo "<p>Discount: " . number_format($test_discount_amount) . " VNĐ</p>";
echo "<p>Final Total: " . number_format($test_final_total) . " VNĐ</p>";

mysqli_begin_transaction($conn);

try {
    // Create order
    $order_sql = "INSERT INTO orders (user_id, address_id, total_amount, platform_fee, status, voucher_id) VALUES (?, ?, ?, 0, 'pending', ?)";
    $order_stmt = mysqli_prepare($conn, $order_sql);
    mysqli_stmt_bind_param($order_stmt, "iidd", $test_user_id, $test_address_id, $test_final_total, $test_voucher_id);
    mysqli_stmt_execute($order_stmt);
    $order_id = mysqli_insert_id($conn);
    mysqli_stmt_close($order_stmt);
    
    echo "<p style='color: green;'>✅ Test order created with ID: $order_id</p>";
    
    // Record voucher usage
    $usage_sql = "INSERT INTO voucher_usage (voucher_id, user_id, order_id, discount_applied) VALUES (?, ?, ?, ?)";
    $usage_stmt = mysqli_prepare($conn, $usage_sql);
    mysqli_stmt_bind_param($usage_stmt, "iiid", $test_voucher_id, $test_user_id, $order_id, $test_discount_amount);
    $usage_result = mysqli_stmt_execute($usage_stmt);
    mysqli_stmt_close($usage_stmt);
    
    if ($usage_result) {
        echo "<p style='color: green;'>✅ Test voucher usage recorded successfully</p>";
    } else {
        echo "<p style='color: red;'>❌ Failed to record test voucher usage: " . mysqli_error($conn) . "</p>";
    }
    
    // Add payment
    $pay_sql = "INSERT INTO payments (order_id, payment_method, amount, status) VALUES (?, 'COD', ?, 'pending')";
    $pay_stmt = mysqli_prepare($conn, $pay_sql);
    mysqli_stmt_bind_param($pay_stmt, "id", $order_id, $test_final_total);
    mysqli_stmt_execute($pay_stmt);
    mysqli_stmt_close($pay_stmt);
    
    echo "<p style='color: green;'>✅ Test payment record created</p>";
    
    mysqli_commit($conn);
    echo "<p style='color: green;'>✅ Test transaction committed successfully</p>";
    
} catch (Exception $e) {
    mysqli_rollback($conn);
    echo "<p style='color: red;'>❌ Test Error: " . $e->getMessage() . "</p>";
}

// 5. Kiểm tra voucher TEST2 sau khi test
echo "<h2>5. Check TEST2 Voucher After Test</h2>";
$voucher_after_sql = "
    SELECT 
        v.id,
        v.voucher_code,
        v.quantity,
        (SELECT COUNT(*) FROM voucher_usage WHERE voucher_id = v.id) as used_count
    FROM vouchers v
    WHERE v.id = ?
";

$voucher_after_stmt = mysqli_prepare($conn, $voucher_after_sql);
mysqli_stmt_bind_param($voucher_after_stmt, "i", $test_voucher_id);
mysqli_stmt_execute($voucher_after_stmt);
$voucher_after_result = mysqli_stmt_get_result($voucher_after_stmt);

if ($voucher_after_result && mysqli_num_rows($voucher_after_result) > 0) {
    $voucher_after_data = mysqli_fetch_assoc($voucher_after_result);
    $remaining_after = $voucher_after_data['quantity'] - $voucher_after_data['used_count'];
    
    echo "<p><strong>Voucher:</strong> {$voucher_after_data['voucher_code']}</p>";
    echo "<p><strong>Total Quantity:</strong> {$voucher_after_data['quantity']}</p>";
    echo "<p><strong>Used Count:</strong> {$voucher_after_data['used_count']}</p>";
    echo "<p><strong>Remaining:</strong> $remaining_after</p>";
    
    if ($remaining_after < 100) {
        echo "<p style='color: green;'>✅ Voucher quantity decreased correctly!</p>";
    } else {
        echo "<p style='color: red;'>❌ Voucher quantity did not decrease!</p>";
    }
}

mysqli_close($conn);
?> 