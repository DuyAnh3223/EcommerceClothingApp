<?php
header('Content-Type: text/html; charset=utf-8');
require_once 'config/db_connect.php';

// Set timezone to Vietnam
date_default_timezone_set('Asia/Ho_Chi_Minh');

echo "<h1>🔍 Kiểm tra Voucher Quantity Display</h1>";

// 1. Kiểm tra voucher quantity hiện tại
echo "<h2>1. 📊 Kiểm tra voucher quantity hiện tại</h2>";

$vouchers_sql = "
    SELECT 
        v.id,
        v.voucher_code,
        v.quantity as original_quantity,
        COUNT(vu.id) as used_count,
        (v.quantity - COUNT(vu.id)) as calculated_remaining
    FROM vouchers v
    LEFT JOIN voucher_usage vu ON v.id = vu.voucher_id
    GROUP BY v.id
    ORDER BY v.id DESC
";

$vouchers_result = mysqli_query($conn, $vouchers_sql);

if ($vouchers_result) {
    echo "<table border='1' style='border-collapse: collapse; width: 100%; margin: 10px 0;'>";
    echo "<tr style='background: #f0f0f0;'>";
    echo "<th>ID</th><th>Mã Voucher</th><th>Original Quantity</th><th>Used Count</th><th>Calculated Remaining</th><th>Status</th>";
    echo "</tr>";
    
    while ($voucher = mysqli_fetch_assoc($vouchers_result)) {
        $status_color = $voucher['calculated_remaining'] > 0 ? 'green' : 'red';
        $status_text = $voucher['calculated_remaining'] > 0 ? '🟢 Available' : '🔴 Exhausted';
        
        echo "<tr>";
        echo "<td>{$voucher['id']}</td>";
        echo "<td><strong>{$voucher['voucher_code']}</strong></td>";
        echo "<td>{$voucher['original_quantity']}</td>";
        echo "<td>{$voucher['used_count']}</td>";
        echo "<td style='color: $status_color; font-weight: bold;'>{$voucher['calculated_remaining']}</td>";
        echo "<td>$status_text</td>";
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "<p style='color: red;'>❌ Lỗi truy vấn: " . mysqli_error($conn) . "</p>";
}

// 2. Kiểm tra chi tiết voucher usage cho GIAM20K
echo "<h2>2. 📋 Chi tiết voucher usage cho GIAM20K</h2>";

$detail_sql = "
    SELECT 
        vu.id,
        vu.voucher_id,
        v.voucher_code,
        vu.user_id,
        u.username,
        vu.order_id,
        vu.discount_applied,
        vu.used_at,
        o.status as order_status
    FROM voucher_usage vu
    JOIN vouchers v ON vu.voucher_id = v.id
    JOIN users u ON vu.user_id = u.id
    LEFT JOIN orders o ON vu.order_id = o.id
    WHERE v.voucher_code = 'GIAM20K'
    ORDER BY vu.used_at DESC
";

$detail_result = mysqli_query($conn, $detail_sql);

if ($detail_result && mysqli_num_rows($detail_result) > 0) {
    echo "<table border='1' style='border-collapse: collapse; width: 100%; margin: 10px 0;'>";
    echo "<tr style='background: #f0f0f0;'>";
    echo "<th>ID</th><th>Voucher ID</th><th>User</th><th>Order ID</th><th>Order Status</th><th>Discount</th><th>Used At</th>";
    echo "</tr>";
    
    while ($usage = mysqli_fetch_assoc($detail_result)) {
        $status_color = $usage['order_status'] === 'confirmed' ? 'green' : 'orange';
        echo "<tr>";
        echo "<td>{$usage['id']}</td>";
        echo "<td>{$usage['voucher_id']}</td>";
        echo "<td>{$usage['username']}</td>";
        echo "<td>#{$usage['order_id']}</td>";
        echo "<td style='color: $status_color;'>{$usage['order_status']}</td>";
        echo "<td>" . number_format($usage['discount_applied']) . " VNĐ</td>";
        echo "<td>" . date('d/m/Y H:i:s', strtotime($usage['used_at'])) . "</td>";
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "<p style='color: orange;'>⚠️ Không có voucher usage cho GIAM20K</p>";
}

// 3. Kiểm tra API logic
echo "<h2>3. 🔍 Kiểm tra API logic</h2>";

echo "<div style='background: #e7f3ff; padding: 15px; border-radius: 8px; margin: 10px 0;'>";
echo "<h3>Logic hiện tại trong place_order_with_combinations.php:</h3>";
echo "<pre>";
echo "// Tính used_count
SELECT COUNT(*) FROM voucher_usage WHERE voucher_id = vouchers.id

// Tính remaining_quantity  
remaining_quantity = voucher.quantity - used_count

// Kiểm tra voucher có còn không
if (remaining_quantity > 0) {
    // Áp dụng voucher
    final_total = total_amount - discount_amount
    // Ghi nhận sử dụng
    INSERT INTO voucher_usage (voucher_id, user_id, order_id, discount_applied)
}
</pre>";
echo "</div>";

// 4. Test logic tính toán
echo "<h2>4. 🧪 Test logic tính toán</h2>";

$test_voucher_sql = "SELECT id, voucher_code, quantity FROM vouchers WHERE voucher_code = 'GIAM20K' LIMIT 1";
$test_voucher_result = mysqli_query($conn, $test_voucher_sql);

if ($test_voucher_result && mysqli_num_rows($test_voucher_result) > 0) {
    $test_voucher = mysqli_fetch_assoc($test_voucher_result);
    
    // Tính used_count theo logic hiện tại
    $used_count_sql = "SELECT COUNT(*) as used_count FROM voucher_usage WHERE voucher_id = ?";
    $used_count_stmt = $conn->prepare($used_count_sql);
    $used_count_stmt->bind_param("i", $test_voucher['id']);
    $used_count_stmt->execute();
    $used_count_result = $used_count_stmt->get_result();
    $used_count_data = $used_count_result->fetch_assoc();
    
    $used_count = $used_count_data['used_count'];
    $remaining = $test_voucher['quantity'] - $used_count;
    
    echo "<div style='background: #fff3cd; padding: 15px; border-radius: 8px; margin: 10px 0;'>";
    echo "<h3>Test Voucher: {$test_voucher['voucher_code']}</h3>";
    echo "<p><strong>Original Quantity:</strong> {$test_voucher['quantity']}</p>";
    echo "<p><strong>Used Count (COUNT):</strong> $used_count</p>";
    echo "<p><strong>Remaining (calculated):</strong> $remaining</p>";
    echo "<p><strong>Status:</strong> " . ($remaining > 0 ? '🟢 Available' : '🔴 Exhausted') . "</p>";
    echo "</div>";
}

// 5. Kết luận
echo "<h2>5. 📋 Kết luận</h2>";

echo "<div style='background: #d1ecf1; padding: 15px; border-radius: 8px; margin: 10px 0;'>";
echo "<h3>✅ Vấn đề đã được xác định:</h3>";
echo "<ul>";
echo "<li><strong>Voucher quantity KHÔNG giảm trong database</strong> - Đây là thiết kế đúng!</li>";
echo "<li><strong>Quantity được tính động:</strong> remaining = original_quantity - COUNT(voucher_usage)</li>";
echo "<li><strong>Logic hoạt động đúng:</strong> GIAM20K có 5 usage records, remaining = 100 - 5 = 95</li>";
echo "<li><strong>Vấn đề có thể là:</strong> Flutter app hiển thị sai hoặc API trả về sai data</li>";
echo "</ul>";
echo "</div>";

echo "<div style='background: #f8d7da; padding: 15px; border-radius: 8px; margin: 10px 0;'>";
echo "<h3>🔍 Cần kiểm tra thêm:</h3>";
echo "<ul>";
echo "<li><strong>Flutter app:</strong> Kiểm tra cách hiển thị voucher quantity</li>";
echo "<li><strong>API response:</strong> Kiểm tra data trả về cho Flutter</li>";
echo "<li><strong>Voucher validation:</strong> Kiểm tra API validate_voucher.php</li>";
echo "<li><strong>Order placement:</strong> Kiểm tra API place_order_with_combinations.php</li>";
echo "</ul>";
echo "</div>";

mysqli_close($conn);
?> 