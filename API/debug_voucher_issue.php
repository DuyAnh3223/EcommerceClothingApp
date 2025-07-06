<?php
header('Content-Type: text/html; charset=utf-8');
require_once 'config/db_connect.php';

echo "<h1>🔍 Debug Voucher Issue</h1>";

// Kiểm tra voucher GIAM20K
echo "<h2>1. Kiểm tra voucher GIAM20K</h2>";
$voucher_sql = "
    SELECT 
        v.id,
        v.voucher_code,
        v.discount_amount,
        v.quantity,
        v.start_date,
        v.end_date,
        COUNT(vu.id) as used_count,
        (v.quantity - COUNT(vu.id)) as remaining_quantity
    FROM vouchers v
    LEFT JOIN voucher_usage vu ON v.id = vu.voucher_id
    WHERE v.voucher_code = 'GIAM20K'
    GROUP BY v.id
";

$voucher_result = mysqli_query($conn, $voucher_sql);

if ($voucher_result && mysqli_num_rows($voucher_result) > 0) {
    $voucher = mysqli_fetch_assoc($voucher_result);
    echo "<p><strong>Voucher ID:</strong> {$voucher['id']}</p>";
    echo "<p><strong>Code:</strong> {$voucher['voucher_code']}</p>";
    echo "<p><strong>Discount:</strong> " . number_format($voucher['discount_amount']) . " VNĐ</p>";
    echo "<p><strong>Total Quantity:</strong> {$voucher['quantity']}</p>";
    echo "<p><strong>Used Count:</strong> {$voucher['used_count']}</p>";
    echo "<p><strong>Remaining:</strong> {$voucher['remaining_quantity']}</p>";
    echo "<p><strong>Start Date:</strong> {$voucher['start_date']}</p>";
    echo "<p><strong>End Date:</strong> {$voucher['end_date']}</p>";
} else {
    echo "<p style='color: red;'>❌ Voucher GIAM20K không tồn tại</p>";
}

// Kiểm tra tất cả voucher usage
echo "<h2>2. Tất cả voucher usage</h2>";
$usage_sql = "
    SELECT 
        vu.id,
        vu.voucher_id,
        v.voucher_code,
        u.username,
        vu.order_id,
        vu.discount_applied,
        vu.used_at
    FROM voucher_usage vu
    JOIN vouchers v ON vu.voucher_id = v.id
    JOIN users u ON vu.user_id = u.id
    ORDER BY vu.used_at DESC
";

$usage_result = mysqli_query($conn, $usage_sql);

if ($usage_result && mysqli_num_rows($usage_result) > 0) {
    echo "<table border='1' style='border-collapse: collapse; width: 100%;'>";
    echo "<tr style='background: #f0f0f0;'>";
    echo "<th>ID</th><th>Voucher ID</th><th>Code</th><th>User</th><th>Order ID</th><th>Discount</th><th>Used At</th>";
    echo "</tr>";
    
    while ($usage = mysqli_fetch_assoc($usage_result)) {
        echo "<tr>";
        echo "<td>{$usage['id']}</td>";
        echo "<td>{$usage['voucher_id']}</td>";
        echo "<td>{$usage['voucher_code']}</td>";
        echo "<td>{$usage['username']}</td>";
        echo "<td>#{$usage['order_id']}</td>";
        echo "<td>" . number_format($usage['discount_applied']) . " VNĐ</td>";
        echo "<td>{$usage['used_at']}</td>";
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "<p style='color: orange;'>⚠️ Chưa có voucher usage nào</p>";
}

// Kiểm tra đơn hàng gần đây
echo "<h2>3. Đơn hàng gần đây</h2>";
$orders_sql = "
    SELECT 
        o.id,
        o.user_id,
        o.total_amount,
        o.voucher_id,
        u.username,
        o.created_at
    FROM orders o
    JOIN users u ON o.user_id = u.id
    ORDER BY o.created_at DESC
    LIMIT 10
";

$orders_result = mysqli_query($conn, $orders_sql);

if ($orders_result && mysqli_num_rows($orders_result) > 0) {
    echo "<table border='1' style='border-collapse: collapse; width: 100%;'>";
    echo "<tr style='background: #f0f0f0;'>";
    echo "<th>Order ID</th><th>User</th><th>Total Amount</th><th>Voucher ID</th><th>Created At</th>";
    echo "</tr>";
    
    while ($order = mysqli_fetch_assoc($orders_result)) {
        $voucher_info = $order['voucher_id'] ? "Voucher ID: {$order['voucher_id']}" : "Không có voucher";
        echo "<tr>";
        echo "<td>#{$order['id']}</td>";
        echo "<td>{$order['username']}</td>";
        echo "<td>" . number_format($order['total_amount']) . " VNĐ</td>";
        echo "<td>{$voucher_info}</td>";
        echo "<td>{$order['created_at']}</td>";
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "<p style='color: orange;'>⚠️ Không có đơn hàng nào</p>";
}

// Test logic voucher validation
echo "<h2>4. Test Logic Voucher Validation</h2>";
$test_voucher_id = 11; // ID của voucher GIAM20K
$test_discount = 20000;

$test_sql = "
    SELECT 
        v.id,
        v.voucher_code,
        v.discount_amount,
        v.quantity,
        (SELECT COUNT(*) FROM voucher_usage WHERE voucher_id = v.id) as used_count
    FROM vouchers v
    WHERE v.id = ?
";

$test_stmt = mysqli_prepare($conn, $test_sql);
mysqli_stmt_bind_param($test_stmt, "i", $test_voucher_id);
mysqli_stmt_execute($test_stmt);
$test_result = mysqli_stmt_get_result($test_stmt);

if ($test_result && mysqli_num_rows($test_result) > 0) {
    $test_voucher = mysqli_fetch_assoc($test_result);
    $remaining_quantity = $test_voucher['quantity'] - $test_voucher['used_count'];
    
    echo "<p><strong>Test Voucher:</strong> {$test_voucher['voucher_code']}</p>";
    echo "<p><strong>Total Quantity:</strong> {$test_voucher['quantity']}</p>";
    echo "<p><strong>Used Count:</strong> {$test_voucher['used_count']}</p>";
    echo "<p><strong>Remaining:</strong> {$remaining_quantity}</p>";
    
    if ($remaining_quantity > 0) {
        echo "<p style='color: green;'>✅ Voucher có thể sử dụng</p>";
        echo "<p><strong>Expected:</strong> Sau khi sử dụng, remaining sẽ là " . ($remaining_quantity - 1) . "</p>";
    } else {
        echo "<p style='color: red;'>❌ Voucher đã hết số lượng</p>";
    }
} else {
    echo "<p style='color: red;'>❌ Không tìm thấy voucher test</p>";
}

mysqli_close($conn);
?> 