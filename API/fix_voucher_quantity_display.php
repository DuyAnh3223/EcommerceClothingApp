<?php
header('Content-Type: text/html; charset=utf-8');
require_once 'config/db_connect.php';

echo "<h1>🔧 Fix Voucher Quantity Display Issue</h1>";

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
    
    if ($remaining == $voucher['quantity']) {
        echo "<p style='color: red;'><strong>❌ Vấn đề: Số lượng voucher không được cập nhật!</strong></p>";
    } else {
        echo "<p style='color: green;'><strong>✅ Voucher quantity đã được cập nhật đúng</strong></p>";
    }
} else {
    echo "<p style='color: red;'>❌ Voucher TEST2 không tồn tại</p>";
}

// Check if there are any orders with TEST2 voucher but no usage records
echo "<h2>2. Check for Missing Voucher Usage Records</h2>";
$missing_usage_sql = "
    SELECT 
        o.id as order_id,
        o.user_id,
        o.total_amount,
        o.voucher_id,
        o.created_at,
        v.voucher_code
    FROM orders o
    JOIN vouchers v ON o.voucher_id = v.id
    LEFT JOIN voucher_usage vu ON o.id = vu.order_id
    WHERE v.voucher_code = 'TEST2' AND vu.id IS NULL
    ORDER BY o.created_at DESC
";

$missing_usage_result = mysqli_query($conn, $missing_usage_sql);

if ($missing_usage_result && mysqli_num_rows($missing_usage_result) > 0) {
    echo "<p style='color: red;'><strong>❌ Found " . mysqli_num_rows($missing_usage_result) . " orders with TEST2 voucher but no usage records:</strong></p>";
    echo "<table border='1' style='border-collapse: collapse; width: 100%;'>";
    echo "<tr><th>Order ID</th><th>User ID</th><th>Total Amount</th><th>Voucher ID</th><th>Created At</th></tr>";
    
    while ($order = mysqli_fetch_assoc($missing_usage_result)) {
        echo "<tr>";
        echo "<td>{$order['order_id']}</td>";
        echo "<td>{$order['user_id']}</td>";
        echo "<td>" . number_format($order['total_amount']) . " VNĐ</td>";
        echo "<td>{$order['voucher_id']}</td>";
        echo "<td>{$order['created_at']}</td>";
        echo "</tr>";
    }
    echo "</table>";
    
    // Fix missing voucher usage records
    echo "<h3>3. Fix Missing Voucher Usage Records</h3>";
    
    $missing_usage_result = mysqli_query($conn, $missing_usage_sql);
    $fixed_count = 0;
    
    while ($order = mysqli_fetch_assoc($missing_usage_result)) {
        // Calculate discount amount (simplified)
        $discount_amount = 5000; // Default discount for TEST2
        
        $fix_usage_sql = "INSERT INTO voucher_usage (voucher_id, user_id, order_id, discount_applied) VALUES (?, ?, ?, ?)";
        $fix_usage_stmt = mysqli_prepare($conn, $fix_usage_sql);
        $fix_usage_stmt->bind_param("iiid", $order['voucher_id'], $order['user_id'], $order['order_id'], $discount_amount);
        $fix_result = $fix_usage_stmt->execute();
        $fix_usage_stmt->close();
        
        if ($fix_result) {
            echo "<p style='color: green;'>✅ Fixed voucher usage for order #{$order['order_id']}</p>";
            $fixed_count++;
        } else {
            echo "<p style='color: red;'>❌ Failed to fix voucher usage for order #{$order['order_id']}</p>";
        }
    }
    
    echo "<p><strong>Fixed $fixed_count missing voucher usage records</strong></p>";
} else {
    echo "<p style='color: green;'>✅ No missing voucher usage records found</p>";
}

// Check voucher status after fix
echo "<h2>4. Check Voucher Status After Fix</h2>";
$voucher_after_sql = "
    SELECT 
        v.id,
        v.voucher_code,
        v.discount_amount,
        v.quantity,
        (SELECT COUNT(*) FROM voucher_usage WHERE voucher_id = v.id) as used_count
    FROM vouchers v
    WHERE v.voucher_code = 'TEST2'
";

$voucher_after_result = mysqli_query($conn, $voucher_after_sql);

if ($voucher_after_result && mysqli_num_rows($voucher_after_result) > 0) {
    $voucher_after = mysqli_fetch_assoc($voucher_after_result);
    $remaining_after = $voucher_after['quantity'] - $voucher_after['used_count'];
    
    echo "<p><strong>Voucher ID:</strong> {$voucher_after['id']}</p>";
    echo "<p><strong>Code:</strong> {$voucher_after['voucher_code']}</p>";
    echo "<p><strong>Discount:</strong> " . number_format($voucher_after['discount_amount']) . " VNĐ</p>";
    echo "<p><strong>Total Quantity:</strong> {$voucher_after['quantity']}</p>";
    echo "<p><strong>Used Count:</strong> {$voucher_after['used_count']}</p>";
    echo "<p><strong>Remaining:</strong> $remaining_after</p>";
    
    if ($remaining_after < $voucher_after['quantity']) {
        echo "<p style='color: green;'><strong>✅ Voucher quantity now displays correctly!</strong></p>";
    } else {
        echo "<p style='color: red;'><strong>❌ Voucher quantity still not updated</strong></p>";
    }
}

// Check all voucher usage records for TEST2
echo "<h2>5. All Voucher Usage Records for TEST2</h2>";
$all_usage_sql = "
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

$all_usage_result = mysqli_query($conn, $all_usage_sql);

if ($all_usage_result && mysqli_num_rows($all_usage_result) > 0) {
    echo "<p><strong>Total " . mysqli_num_rows($all_usage_result) . " voucher usage records:</strong></p>";
    echo "<table border='1' style='border-collapse: collapse; width: 100%;'>";
    echo "<tr><th>ID</th><th>Voucher ID</th><th>User ID</th><th>Order ID</th><th>Discount</th><th>Used At</th></tr>";
    
    while ($usage = mysqli_fetch_assoc($all_usage_result)) {
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
    echo "<p style='color: orange;'>⚠️ No voucher usage records found for TEST2</p>";
}

echo "<h2>6. Recommendations</h2>";
echo "<h3>Để tránh vấn đề này trong tương lai:</h3>";
echo "<ol>";
echo "<li><strong>Kiểm tra Flutter app:</strong> Đảm bảo Flutter gửi voucher_id đúng cách</li>";
echo "<li><strong>Thêm validation:</strong> Kiểm tra voucher_id trước khi tạo order</li>";
echo "<li><strong>Thêm error handling:</strong> Xử lý lỗi khi ghi nhận voucher usage</li>";
echo "<li><strong>Thêm logging:</strong> Ghi log chi tiết cho voucher processing</li>";
echo "</ol>";

echo "<h3>Debug steps:</h3>";
echo "<ol>";
echo "<li>Chạy Flutter app và kiểm tra logs khi đặt hàng với voucher</li>";
echo "<li>Kiểm tra API error logs</li>";
echo "<li>Test với Postman để xác định vấn đề</li>";
echo "<li>Kiểm tra voucher_id trong request từ Flutter</li>";
echo "</ol>";

mysqli_close($conn);
?> 