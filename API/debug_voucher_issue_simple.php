<?php
header('Content-Type: text/html; charset=utf-8');
require_once 'config/db_connect.php';

echo "<h1>🔍 Debug Voucher Issue - Simple</h1>";

// 1. Kiểm tra voucher GIAM20K hiện tại
echo "<h2>1. Kiểm tra voucher GIAM20K</h2>";
$voucher_sql = "
    SELECT 
        v.id,
        v.voucher_code,
        v.discount_amount,
        v.quantity,
        (SELECT COUNT(*) FROM voucher_usage WHERE voucher_id = v.id) as used_count
    FROM vouchers v
    WHERE v.voucher_code = 'GIAM20K'
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
    echo "<p style='color: red;'>❌ Voucher GIAM20K không tồn tại</p>";
}

// 2. Kiểm tra voucher usage records
echo "<h2>2. Kiểm tra voucher usage records</h2>";
$usage_sql = "
    SELECT 
        vu.id,
        vu.voucher_id,
        vu.user_id,
        vu.order_id,
        vu.discount_applied,
        vu.created_at,
        v.voucher_code
    FROM voucher_usage vu
    JOIN vouchers v ON vu.voucher_id = v.id
    WHERE v.voucher_code = 'GIAM20K'
    ORDER BY vu.created_at DESC
";

$usage_result = mysqli_query($conn, $usage_sql);

if ($usage_result && mysqli_num_rows($usage_result) > 0) {
    echo "<p><strong>Found " . mysqli_num_rows($usage_result) . " usage records:</strong></p>";
    echo "<table border='1' style='border-collapse: collapse; width: 100%;'>";
    echo "<tr><th>ID</th><th>Voucher ID</th><th>User ID</th><th>Order ID</th><th>Discount</th><th>Created At</th></tr>";
    
    while ($usage = mysqli_fetch_assoc($usage_result)) {
        echo "<tr>";
        echo "<td>{$usage['id']}</td>";
        echo "<td>{$usage['voucher_id']}</td>";
        echo "<td>{$usage['user_id']}</td>";
        echo "<td>{$usage['order_id']}</td>";
        echo "<td>" . number_format($usage['discount_applied']) . " VNĐ</td>";
        echo "<td>{$usage['created_at']}</td>";
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "<p style='color: orange;'>⚠️ Không có usage records cho voucher GIAM20K</p>";
}

// 3. Kiểm tra orders gần đây
echo "<h2>3. Kiểm tra orders gần đây</h2>";
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
    ORDER BY o.created_at DESC
    LIMIT 10
";

$orders_result = mysqli_query($conn, $orders_sql);

if ($orders_result && mysqli_num_rows($orders_result) > 0) {
    echo "<p><strong>Recent orders:</strong></p>";
    echo "<table border='1' style='border-collapse: collapse; width: 100%;'>";
    echo "<tr><th>Order ID</th><th>User ID</th><th>Total Amount</th><th>Voucher ID</th><th>Voucher Code</th><th>Created At</th></tr>";
    
    while ($order = mysqli_fetch_assoc($orders_result)) {
        echo "<tr>";
        echo "<td>{$order['id']}</td>";
        echo "<td>{$order['user_id']}</td>";
        echo "<td>" . number_format($order['total_amount']) . " VNĐ</td>";
        echo "<td>{$order['voucher_id']}</td>";
        echo "<td>{$order['voucher_code']}</td>";
        echo "<td>{$order['created_at']}</td>";
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "<p style='color: orange;'>⚠️ Không có orders nào</p>";
}

// 4. Test tạo voucher usage record
echo "<h2>4. Test tạo voucher usage record</h2>";

$test_voucher_id = 11; // GIAM20K
$test_user_id = 4;
$test_order_id = 999; // Test order ID
$test_discount = 20000;

echo "<p>Thử tạo voucher usage record:</p>";
echo "<p>Voucher ID: $test_voucher_id</p>";
echo "<p>User ID: $test_user_id</p>";
echo "<p>Order ID: $test_order_id</p>";
echo "<p>Discount: " . number_format($test_discount) . " VNĐ</p>";

$insert_sql = "INSERT INTO voucher_usage (voucher_id, user_id, order_id, discount_applied) VALUES (?, ?, ?, ?)";
$insert_stmt = mysqli_prepare($conn, $insert_sql);

if ($insert_stmt) {
    mysqli_stmt_bind_param($insert_stmt, "iiid", $test_voucher_id, $test_user_id, $test_order_id, $test_discount);
    $insert_result = mysqli_stmt_execute($insert_stmt);
    
    if ($insert_result) {
        echo "<p style='color: green;'>✅ Tạo voucher usage record thành công!</p>";
        
        // Kiểm tra lại voucher quantity
        $check_sql = "
            SELECT 
                v.quantity,
                (SELECT COUNT(*) FROM voucher_usage WHERE voucher_id = v.id) as used_count
            FROM vouchers v
            WHERE v.id = ?
        ";
        $check_stmt = mysqli_prepare($conn, $check_sql);
        mysqli_stmt_bind_param($check_stmt, "i", $test_voucher_id);
        mysqli_stmt_execute($check_stmt);
        $check_result = mysqli_stmt_get_result($check_stmt);
        $check_data = mysqli_fetch_assoc($check_result);
        
        $new_remaining = $check_data['quantity'] - $check_data['used_count'];
        echo "<p><strong>New remaining quantity:</strong> $new_remaining</p>";
        
    } else {
        echo "<p style='color: red;'>❌ Lỗi tạo voucher usage record: " . mysqli_error($conn) . "</p>";
    }
    mysqli_stmt_close($insert_stmt);
} else {
    echo "<p style='color: red;'>❌ Lỗi prepare statement: " . mysqli_error($conn) . "</p>";
}

mysqli_close($conn);
?> 