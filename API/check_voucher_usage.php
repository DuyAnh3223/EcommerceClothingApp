<?php
header('Content-Type: text/html; charset=utf-8');
require_once 'config/db_connect.php';

// Set timezone to Vietnam
date_default_timezone_set('Asia/Ho_Chi_Minh');

echo "<h1>📊 Kiểm tra Voucher Usage</h1>";

// Lấy danh sách tất cả voucher
$vouchers_sql = "
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
    GROUP BY v.id
    ORDER BY v.id DESC
";

$vouchers_result = mysqli_query($conn, $vouchers_sql);

if (!$vouchers_result) {
    echo "<p style='color: red;'>❌ Lỗi truy vấn: " . mysqli_error($conn) . "</p>";
    exit;
}

echo "<table border='1' style='border-collapse: collapse; width: 100%; margin: 20px 0;'>";
echo "<tr style='background: #f0f0f0;'>";
echo "<th>ID</th>";
echo "<th>Mã Voucher</th>";
echo "<th>Giảm giá</th>";
echo "<th>Tổng số lượng</th>";
echo "<th>Đã sử dụng</th>";
echo "<th>Còn lại</th>";
echo "<th>Trạng thái</th>";
echo "<th>Thời gian bắt đầu</th>";
echo "<th>Thời gian kết thúc</th>";
echo "</tr>";

while ($voucher = mysqli_fetch_assoc($vouchers_result)) {
    $remaining = $voucher['remaining_quantity'];
    $status_color = $remaining > 0 ? 'green' : 'red';
    $status_text = $remaining > 0 ? '🟢 Còn hàng' : '🔴 Hết hàng';
    
    echo "<tr>";
    echo "<td>{$voucher['id']}</td>";
    echo "<td><strong>{$voucher['voucher_code']}</strong></td>";
    echo "<td>" . number_format($voucher['discount_amount']) . " VNĐ</td>";
    echo "<td>{$voucher['quantity']}</td>";
    echo "<td>{$voucher['used_count']}</td>";
    echo "<td style='color: $status_color; font-weight: bold;'>{$voucher['remaining_quantity']}</td>";
    echo "<td>$status_text</td>";
    echo "<td>" . date('d/m/Y H:i', strtotime($voucher['start_date'])) . "</td>";
    echo "<td>" . date('d/m/Y H:i', strtotime($voucher['end_date'])) . "</td>";
    echo "</tr>";
}
echo "</table>";

// Hiển thị chi tiết voucher usage
echo "<h2>📋 Chi tiết Voucher Usage</h2>";

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
    LIMIT 20
";

$usage_result = mysqli_query($conn, $usage_sql);

if ($usage_result && mysqli_num_rows($usage_result) > 0) {
    echo "<table border='1' style='border-collapse: collapse; width: 100%; margin: 20px 0;'>";
    echo "<tr style='background: #f0f0f0;'>";
    echo "<th>ID Usage</th>";
    echo "<th>Voucher ID</th>";
    echo "<th>Mã Voucher</th>";
    echo "<th>User</th>";
    echo "<th>Order ID</th>";
    echo "<th>Giảm giá áp dụng</th>";
    echo "<th>Thời gian sử dụng</th>";
    echo "</tr>";
    
    while ($usage = mysqli_fetch_assoc($usage_result)) {
        echo "<tr>";
        echo "<td>{$usage['id']}</td>";
        echo "<td>{$usage['voucher_id']}</td>";
        echo "<td><strong>{$usage['voucher_code']}</strong></td>";
        echo "<td>{$usage['username']}</td>";
        echo "<td>#{$usage['order_id']}</td>";
        echo "<td>" . number_format($usage['discount_applied']) . " VNĐ</td>";
        echo "<td>" . date('d/m/Y H:i:s', strtotime($usage['used_at'])) . "</td>";
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "<p style='color: orange;'>⚠️ Chưa có voucher nào được sử dụng</p>";
}

// Test voucher cụ thể
echo "<h2>🧪 Test Voucher GIAM20K</h2>";

$test_voucher_sql = "
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

$test_result = mysqli_query($conn, $test_voucher_sql);

if ($test_result && mysqli_num_rows($test_result) > 0) {
    $test_voucher = mysqli_fetch_assoc($test_result);
    
    echo "<div style='background: #e7f3ff; padding: 15px; border-radius: 8px; margin: 10px 0;'>";
    echo "<h3>Thông tin Voucher GIAM20K:</h3>";
    echo "<p><strong>ID:</strong> {$test_voucher['id']}</p>";
    echo "<p><strong>Mã:</strong> {$test_voucher['voucher_code']}</p>";
    echo "<p><strong>Giảm giá:</strong> " . number_format($test_voucher['discount_amount']) . " VNĐ</p>";
    echo "<p><strong>Tổng số lượng:</strong> {$test_voucher['quantity']}</p>";
    echo "<p><strong>Đã sử dụng:</strong> {$test_voucher['used_count']}</p>";
    echo "<p><strong>Còn lại:</strong> <span style='color: " . ($test_voucher['remaining_quantity'] > 0 ? 'green' : 'red') . "; font-weight: bold;'>{$test_voucher['remaining_quantity']}</span></p>";
    echo "<p><strong>Bắt đầu:</strong> " . date('d/m/Y H:i', strtotime($test_voucher['start_date'])) . "</p>";
    echo "<p><strong>Kết thúc:</strong> " . date('d/m/Y H:i', strtotime($test_voucher['end_date'])) . "</p>";
    echo "</div>";
} else {
    echo "<p style='color: red;'>❌ Không tìm thấy voucher GIAM20K</p>";
}

mysqli_close($conn);
?> 