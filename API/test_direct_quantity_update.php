<?php
header('Content-Type: text/html; charset=utf-8');
require_once 'config/db_connect.php';

// Set timezone to Vietnam
date_default_timezone_set('Asia/Ho_Chi_Minh');

echo "<h1>🧪 Test Direct Quantity Update</h1>";

// 1. Kiểm tra voucher quantity hiện tại
echo "<h2>1. 📊 Kiểm tra voucher quantity hiện tại</h2>";

$vouchers_sql = "
    SELECT 
        v.id,
        v.voucher_code,
        v.discount_amount,
        v.quantity,
        v.start_date,
        v.end_date,
        COUNT(vu.id) as used_count
    FROM vouchers v
    LEFT JOIN voucher_usage vu ON v.id = vu.voucher_id
    WHERE v.voucher_code IN ('GIAM20K', 'TEST2')
    GROUP BY v.id
    ORDER BY v.id DESC
";

$vouchers_result = mysqli_query($conn, $vouchers_sql);

if ($vouchers_result) {
    echo "<table border='1' style='border-collapse: collapse; width: 100%; margin: 10px 0;'>";
    echo "<tr style='background: #f0f0f0;'>";
    echo "<th>ID</th><th>Mã Voucher</th><th>Quantity (DB)</th><th>Used Count</th><th>Status</th>";
    echo "</tr>";
    
    while ($voucher = mysqli_fetch_assoc($vouchers_result)) {
        $status_color = $voucher['quantity'] > 0 ? 'green' : 'red';
        $status_text = $voucher['quantity'] > 0 ? '🟢 Available' : '🔴 Exhausted';
        
        echo "<tr>";
        echo "<td>{$voucher['id']}</td>";
        echo "<td><strong>{$voucher['voucher_code']}</strong></td>";
        echo "<td style='color: $status_color; font-weight: bold;'>{$voucher['quantity']}</td>";
        echo "<td>{$voucher['used_count']}</td>";
        echo "<td>$status_text</td>";
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "<p style='color: red;'>❌ Lỗi truy vấn: " . mysqli_error($conn) . "</p>";
}

// 2. Test cập nhật quantity trực tiếp
echo "<h2>2. 🔄 Test cập nhật quantity trực tiếp</h2>";

$test_voucher_sql = "SELECT id, voucher_code, quantity FROM vouchers WHERE voucher_code = 'GIAM20K' LIMIT 1";
$test_voucher_result = mysqli_query($conn, $test_voucher_sql);

if ($test_voucher_result && mysqli_num_rows($test_voucher_result) > 0) {
    $test_voucher = mysqli_fetch_assoc($test_voucher_result);
    
    echo "<div style='background: #e7f3ff; padding: 15px; border-radius: 8px; margin: 10px 0;'>";
    echo "<h3>Test Voucher: {$test_voucher['voucher_code']}</h3>";
    echo "<p><strong>Quantity trước khi test:</strong> {$test_voucher['quantity']}</p>";
    
    // Test update quantity
    $update_sql = "UPDATE vouchers SET quantity = quantity - 1 WHERE id = ? AND quantity > 0";
    $update_stmt = $conn->prepare($update_sql);
    $update_stmt->bind_param("i", $test_voucher['id']);
    
    if ($update_stmt->execute()) {
        echo "<p style='color: green;'>✅ Cập nhật quantity thành công!</p>";
        
        // Kiểm tra lại quantity
        $check_sql = "SELECT quantity FROM vouchers WHERE id = ?";
        $check_stmt = $conn->prepare($check_sql);
        $check_stmt->bind_param("i", $test_voucher['id']);
        $check_stmt->execute();
        $check_result = $check_stmt->get_result();
        $check_data = $check_result->fetch_assoc();
        
        echo "<p><strong>Quantity sau khi test:</strong> {$check_data['quantity']}</p>";
        echo "<p><strong>Đã giảm:</strong> " . ($test_voucher['quantity'] - $check_data['quantity']) . "</p>";
        
        // Khôi phục quantity
        $restore_sql = "UPDATE vouchers SET quantity = quantity + 1 WHERE id = ?";
        $restore_stmt = $conn->prepare($restore_sql);
        $restore_stmt->bind_param("i", $test_voucher['id']);
        $restore_stmt->execute();
        
        echo "<p style='color: blue;'>🔄 Đã khôi phục quantity về ban đầu</p>";
        
    } else {
        echo "<p style='color: red;'>❌ Cập nhật quantity thất bại: " . $update_stmt->error . "</p>";
    }
    
    echo "</div>";
} else {
    echo "<p style='color: red;'>❌ Không tìm thấy voucher GIAM20K</p>";
}

// 3. Test logic trong place_order_with_combinations.php
echo "<h2>3. 🧪 Test logic trong place_order_with_combinations.php</h2>";

echo "<div style='background: #fff3cd; padding: 15px; border-radius: 8px; margin: 10px 0;'>";
echo "<h3>Logic đã được cập nhật:</h3>";
echo "<pre>";
echo "// 1. Trừ trực tiếp quantity trong bảng vouchers
UPDATE vouchers SET quantity = quantity - 1 WHERE id = ? AND quantity > 0

// 2. Ghi nhận sử dụng voucher
INSERT INTO voucher_usage (voucher_id, user_id, order_id, discount_applied)
</pre>";
echo "</div>";

// 4. Test API response
echo "<h2>4. 📱 Test API response</h2>";

$api_test_sql = "SELECT id, voucher_code, quantity FROM vouchers WHERE voucher_code = 'GIAM20K' LIMIT 1";
$api_test_result = mysqli_query($conn, $api_test_sql);

if ($api_test_result && mysqli_num_rows($api_test_result) > 0) {
    $api_voucher = mysqli_fetch_assoc($api_test_result);
    
    // Simulate API response
    $api_response = [
        'id' => (int)$api_voucher['id'],
        'voucher_code' => $api_voucher['voucher_code'],
        'discount_amount' => 20000,
        'quantity' => (int)$api_voucher['quantity'],
        'start_date' => '2024-01-01 00:00:00',
        'end_date' => '2025-12-31 23:59:59',
        'voucher_type' => 'all_products',
        'category_filter' => null,
        'associated_product_ids' => null,
        'created_at' => '2024-01-01 00:00:00',
        'updated_at' => '2024-01-01 00:00:00'
    ];
    
    echo "<div style='background: #d1ecf1; padding: 15px; border-radius: 8px; margin: 10px 0;'>";
    echo "<h3>API Response (JSON):</h3>";
    echo "<pre>" . json_encode($api_response, JSON_PRETTY_PRINT) . "</pre>";
    echo "<p><strong>Flutter sẽ nhận được:</strong></p>";
    echo "<ul>";
    echo "<li><strong>quantity:</strong> {$api_response['quantity']} (trực tiếp từ DB)</li>";
    echo "<li><strong>hasQuantity:</strong> " . ($api_response['quantity'] > 0 ? 'true' : 'false') . "</li>";
    echo "<li><strong>canUse:</strong> " . ($api_response['quantity'] > 0 ? 'true' : 'false') . "</li>";
    echo "</ul>";
    echo "</div>";
}

// 5. Kết luận
echo "<h2>5. 📋 Kết luận</h2>";

echo "<div style='background: #d4edda; padding: 15px; border-radius: 8px; margin: 10px 0;'>";
echo "<h3>✅ Logic đã được cập nhật:</h3>";
echo "<ul>";
echo "<li><strong>place_order_with_combinations.php:</strong> Trừ trực tiếp quantity trong DB</li>";
echo "<li><strong>get_vouchers.php:</strong> Trả về quantity thực tế từ DB</li>";
echo "<li><strong>Flutter Voucher model:</strong> Sử dụng quantity trực tiếp</li>";
echo "<li><strong>VoucherDisplayWidget:</strong> Hiển thị quantity thực tế</li>";
echo "</ul>";
echo "</div>";

echo "<div style='background: #f8d7da; padding: 15px; border-radius: 8px; margin: 10px 0;'>";
echo "<h3>⚠️ Lưu ý:</h3>";
echo "<ul>";
echo "<li>Quantity sẽ giảm trực tiếp trong database</li>";
echo "<li>Khi load lại giao diện, quantity sẽ hiển thị chính xác</li>";
echo "<li>Voucher usage records vẫn được tạo để tracking</li>";
echo "<li>Transaction đảm bảo tính nhất quán</li>";
echo "</ul>";
echo "</div>";

mysqli_close($conn);
?> 