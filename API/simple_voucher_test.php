<?php
header('Content-Type: text/html; charset=utf-8');
require_once 'config/db_connect.php';

echo "<h1>🔍 Simple Voucher Test</h1>";

// 1. Kiểm tra voucher GIAM20K
echo "<h2>1. Check Voucher GIAM20K</h2>";
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

// 2. Tạo test order với voucher
echo "<h2>2. Create Test Order with Voucher</h2>";

$user_id = 4;
$address_id = 3;
$voucher_id = 11; // GIAM20K
$discount_amount = 20000;
$total_amount = 200000;
$final_total = $total_amount - $discount_amount;

echo "<p><strong>User ID:</strong> $user_id</p>";
echo "<p><strong>Address ID:</strong> $address_id</p>";
echo "<p><strong>Voucher ID:</strong> $voucher_id</p>";
echo "<p><strong>Original Total:</strong> " . number_format($total_amount) . " VNĐ</p>";
echo "<p><strong>Discount:</strong> " . number_format($discount_amount) . " VNĐ</p>";
echo "<p><strong>Final Total:</strong> " . number_format($final_total) . " VNĐ</p>";

mysqli_begin_transaction($conn);

try {
    // Create order
    $order_sql = "INSERT INTO orders (user_id, address_id, total_amount, platform_fee, status, voucher_id) VALUES (?, ?, ?, 0, 'pending', ?)";
    $order_stmt = mysqli_prepare($conn, $order_sql);
    mysqli_stmt_bind_param($order_stmt, "iidd", $user_id, $address_id, $final_total, $voucher_id);
    mysqli_stmt_execute($order_stmt);
    $order_id = mysqli_insert_id($conn);
    mysqli_stmt_close($order_stmt);
    
    echo "<p style='color: green;'>✅ Order created with ID: $order_id</p>";
    
    // Record voucher usage
    $usage_sql = "INSERT INTO voucher_usage (voucher_id, user_id, order_id, discount_applied) VALUES (?, ?, ?, ?)";
    $usage_stmt = mysqli_prepare($conn, $usage_sql);
    mysqli_stmt_bind_param($usage_stmt, "iiid", $voucher_id, $user_id, $order_id, $discount_amount);
    $usage_result = mysqli_stmt_execute($usage_stmt);
    mysqli_stmt_close($usage_stmt);
    
    if ($usage_result) {
        echo "<p style='color: green;'>✅ Voucher usage recorded successfully</p>";
    } else {
        echo "<p style='color: red;'>❌ Failed to record voucher usage: " . mysqli_error($conn) . "</p>";
    }
    
    // Add payment
    $pay_sql = "INSERT INTO payments (order_id, payment_method, amount, status) VALUES (?, 'COD', ?, 'pending')";
    $pay_stmt = mysqli_prepare($conn, $pay_sql);
    mysqli_stmt_bind_param($pay_stmt, "id", $order_id, $final_total);
    mysqli_stmt_execute($pay_stmt);
    mysqli_stmt_close($pay_stmt);
    
    echo "<p style='color: green;'>✅ Payment record created</p>";
    
    mysqli_commit($conn);
    echo "<p style='color: green;'>✅ Transaction committed successfully</p>";
    
} catch (Exception $e) {
    mysqli_rollback($conn);
    echo "<p style='color: red;'>❌ Error: " . $e->getMessage() . "</p>";
}

// 3. Kiểm tra voucher sau khi tạo order
echo "<h2>3. Check Voucher After Order</h2>";
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
mysqli_stmt_bind_param($voucher_after_stmt, "i", $voucher_id);
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

// 4. Kiểm tra voucher usage records
echo "<h2>4. Check Voucher Usage Records</h2>";
$usage_check_sql = "
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
    WHERE v.voucher_code = 'GIAM20K'
    ORDER BY vu.used_at DESC
";

$usage_check_result = mysqli_query($conn, $usage_check_sql);

if ($usage_check_result && mysqli_num_rows($usage_check_result) > 0) {
    echo "<p><strong>Found " . mysqli_num_rows($usage_check_result) . " usage records:</strong></p>";
    echo "<table border='1' style='border-collapse: collapse; width: 100%;'>";
    echo "<tr><th>ID</th><th>Voucher ID</th><th>User ID</th><th>Order ID</th><th>Discount</th><th>Created At</th></tr>";
    
    while ($usage = mysqli_fetch_assoc($usage_check_result)) {
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
    echo "<p style='color: orange;'>⚠️ Không có usage records cho voucher GIAM20K</p>";
}

mysqli_close($conn);
?> 