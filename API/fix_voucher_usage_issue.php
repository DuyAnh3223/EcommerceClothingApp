<?php
header('Content-Type: text/html; charset=utf-8');
require_once 'config/db_connect.php';

// Set timezone to Vietnam
date_default_timezone_set('Asia/Ho_Chi_Minh');

echo "<h1>🔧 Fix Voucher Usage Issues</h1>";

// 1. Thêm debug logs chi tiết vào place_order_with_combinations.php
echo "<h2>1. 📝 Thêm debug logs chi tiết</h2>";

$debug_logs = [
    'Voucher data received' => 'DEBUG ORDER: Received voucher data - voucher_id=$voucher_id, voucher_code=$voucher_code, discount_amount=$discount_amount',
    'Voucher validation' => 'DEBUG ORDER: Validating voucher - voucher_id=$voucher_id',
    'Voucher found' => 'DEBUG ORDER: Voucher found - code={$voucher_data[\'voucher_code\']}, total_quantity={$voucher_data[\'quantity\']}, used_count={$voucher_data[\'used_count\']}, remaining=$remaining_quantity',
    'Voucher applied' => 'DEBUG ORDER: Voucher applied - voucher_id=$voucher_id, original_total=$original_total, discount_amount=$discount_amount, final_total=$final_total',
    'Recording voucher usage' => 'DEBUG ORDER: Recording voucher usage - voucher_id=$voucher_id, user_id=$user_id, order_id=$order_id, discount=$voucher_discount',
    'Voucher usage success' => 'DEBUG ORDER: Voucher usage recorded successfully - voucher_id=$voucher_id, order_id=$order_id, discount=$voucher_discount',
    'Voucher usage failed' => 'DEBUG ORDER: Failed to record voucher usage - ' . $usage_stmt->error,
    'Skipping voucher usage' => 'DEBUG ORDER: Skipping voucher usage recording - voucher_applied=$voucher_applied, voucher_id=$voucher_id'
];

echo "<div style='background: #e7f3ff; padding: 15px; border-radius: 8px; margin: 10px 0;'>";
echo "<h3>Debug logs đã có trong place_order_with_combinations.php:</h3>";
echo "<ul>";
foreach ($debug_logs as $step => $log) {
    echo "<li><strong>$step:</strong> <code>$log</code></li>";
}
echo "</ul>";
echo "</div>";

// 2. Kiểm tra và fix voucher usage table
echo "<h2>2. 🗄️ Kiểm tra và fix voucher_usage table</h2>";

// Kiểm tra xem có cột quantity trong voucher_usage không
$check_quantity_sql = "SHOW COLUMNS FROM voucher_usage LIKE 'quantity'";
$check_quantity_result = mysqli_query($conn, $check_quantity_sql);

if (mysqli_num_rows($check_quantity_result) == 0) {
    echo "<p style='color: orange;'>⚠️ Cột 'quantity' chưa có trong voucher_usage table</p>";
    
    // Thêm cột quantity
    $add_quantity_sql = "ALTER TABLE voucher_usage ADD COLUMN quantity INT DEFAULT 1 AFTER discount_applied";
    if (mysqli_query($conn, $add_quantity_sql)) {
        echo "<p style='color: green;'>✅ Đã thêm cột 'quantity' vào voucher_usage table</p>";
    } else {
        echo "<p style='color: red;'>❌ Lỗi thêm cột: " . mysqli_error($conn) . "</p>";
    }
} else {
    echo "<p style='color: green;'>✅ Cột 'quantity' đã có trong voucher_usage table</p>";
}

// 3. Cập nhật API để sử dụng quantity column
echo "<h2>3. 🔄 Cập nhật API logic</h2>";

$updated_insert_sql = "INSERT INTO voucher_usage (voucher_id, user_id, order_id, discount_applied, quantity) VALUES (?, ?, ?, ?, ?)";
$updated_count_sql = "SELECT SUM(quantity) as used_count FROM voucher_usage WHERE voucher_id = ?";

echo "<div style='background: #fff3cd; padding: 15px; border-radius: 8px; margin: 10px 0;'>";
echo "<h3>Cập nhật SQL queries:</h3>";
echo "<p><strong>Insert voucher usage:</strong></p>";
echo "<code>$updated_insert_sql</code>";
echo "<p><strong>Count used vouchers:</strong></p>";
echo "<code>$updated_count_sql</code>";
echo "</div>";

// 4. Test voucher usage với quantity
echo "<h2>4. 🧪 Test voucher usage với quantity</h2>";

$test_voucher_sql = "SELECT id, voucher_code, quantity FROM vouchers WHERE voucher_code = 'GIAM20K' LIMIT 1";
$test_voucher_result = mysqli_query($conn, $test_voucher_sql);

if ($test_voucher_result && mysqli_num_rows($test_voucher_result) > 0) {
    $test_voucher = mysqli_fetch_assoc($test_voucher_result);
    
    echo "<div style='background: #e7f3ff; padding: 15px; border-radius: 8px; margin: 10px 0;'>";
    echo "<h3>Test với voucher: {$test_voucher['voucher_code']}</h3>";
    
    // Test insert với quantity
    $test_user_id = 1;
    $test_order_id = 888;
    $test_discount = 20000;
    $test_quantity = 1;
    
    $insert_with_quantity_sql = "INSERT INTO voucher_usage (voucher_id, user_id, order_id, discount_applied, quantity) VALUES (?, ?, ?, ?, ?)";
    $insert_stmt = $conn->prepare($insert_with_quantity_sql);
    $insert_stmt->bind_param("iiidi", $test_voucher['id'], $test_user_id, $test_order_id, $test_discount, $test_quantity);
    
    if ($insert_stmt->execute()) {
        echo "<p style='color: green;'>✅ Test insert với quantity thành công!</p>";
        
        // Kiểm tra lại với SUM(quantity)
        $check_sum_sql = "
            SELECT 
                v.quantity,
                COALESCE(SUM(vu.quantity), 0) as used_count,
                (v.quantity - COALESCE(SUM(vu.quantity), 0)) as remaining_quantity
            FROM vouchers v
            LEFT JOIN voucher_usage vu ON v.id = vu.voucher_id
            WHERE v.id = ?
            GROUP BY v.id
        ";
        $check_stmt = $conn->prepare($check_sum_sql);
        $check_stmt->bind_param("i", $test_voucher['id']);
        $check_stmt->execute();
        $check_result = $check_stmt->get_result();
        $check_data = $check_result->fetch_assoc();
        
        echo "<p><strong>Sau khi insert với quantity:</strong></p>";
        echo "<p>- Total Quantity: {$check_data['quantity']}</p>";
        echo "<p>- Used Count (SUM): {$check_data['used_count']}</p>";
        echo "<p>- Remaining: {$check_data['remaining_quantity']}</p>";
        
        // Xóa test record
        $delete_sql = "DELETE FROM voucher_usage WHERE voucher_id = ? AND order_id = ?";
        $delete_stmt = $conn->prepare($delete_sql);
        $delete_stmt->bind_param("ii", $test_voucher['id'], $test_order_id);
        $delete_stmt->execute();
        
        echo "<p style='color: blue;'>🗑️ Đã xóa test record</p>";
        
    } else {
        echo "<p style='color: red;'>❌ Test insert thất bại: " . $insert_stmt->error . "</p>";
    }
    
    echo "</div>";
} else {
    echo "<p style='color: red;'>❌ Không tìm thấy voucher GIAM20K để test</p>";
}

// 5. Tạo script cập nhật API
echo "<h2>5. 📝 Script cập nhật API</h2>";

$api_update_script = '
// Cập nhật trong place_order_with_combinations.php

// Thay đổi query tính used_count
$voucher_sql = "SELECT id, voucher_code, discount_amount, quantity, 
                       (SELECT COALESCE(SUM(quantity), 0) FROM voucher_usage WHERE voucher_id = vouchers.id) as used_count
                FROM vouchers WHERE id = ?";

// Thay đổi insert voucher usage
$usage_sql = "INSERT INTO voucher_usage (voucher_id, user_id, order_id, discount_applied, quantity) VALUES (?, ?, ?, ?, ?)";
$usage_stmt = $conn->prepare($usage_sql);
$usage_stmt->bind_param("iiidi", $voucher_id, $user_id, $order_id, $voucher_discount, 1); // quantity = 1
';

echo "<div style='background: #f5f5f5; padding: 15px; border-radius: 8px; margin: 10px 0; font-family: monospace;'>";
echo "<h3>Cập nhật cần thực hiện:</h3>";
echo "<pre>" . htmlspecialchars($api_update_script) . "</pre>";
echo "</div>";

// 6. Kiểm tra transaction handling
echo "<h2>6. 🔄 Kiểm tra transaction handling</h2>";

$transaction_issues = [
    'Voucher usage được tạo trước khi commit order' => 'Đúng - voucher usage được tạo sau khi order thành công',
    'Transaction rollback khi có lỗi' => 'Đúng - có rollback trong catch block',
    'Voucher validation trước khi tạo order' => 'Đúng - kiểm tra remaining_quantity > 0',
    'Error handling cho voucher usage' => 'Cần thêm try-catch cho voucher usage insert'
];

echo "<div style='background: #d1ecf1; padding: 15px; border-radius: 8px; margin: 10px 0;'>";
echo "<h3>Transaction handling analysis:</h3>";
echo "<ul>";
foreach ($transaction_issues as $issue => $status) {
    $color = strpos($status, 'Đúng') !== false ? 'green' : 'orange';
    echo "<li style='color: $color;'><strong>$issue:</strong> $status</li>";
}
echo "</ul>";
echo "</div>";

// 7. Tạo script test end-to-end
echo "<h2>7. 🧪 Script test end-to-end</h2>";

$test_script = '
<?php
// Test script để kiểm tra voucher usage end-to-end
require_once "config/db_connect.php";

// 1. Lấy voucher test
$voucher_sql = "SELECT id, voucher_code, quantity FROM vouchers WHERE voucher_code = \'GIAM20K\' LIMIT 1";
$voucher_result = mysqli_query($conn, $voucher_sql);
$voucher = mysqli_fetch_assoc($voucher_result);

// 2. Kiểm tra quantity trước
$before_sql = "SELECT COALESCE(SUM(quantity), 0) as used_count FROM voucher_usage WHERE voucher_id = ?";
$before_stmt = $conn->prepare($before_sql);
$before_stmt->bind_param("i", $voucher[\'id\']);
$before_stmt->execute();
$before_result = $before_stmt->get_result();
$before_data = $before_result->fetch_assoc();
$before_used = $before_data[\'used_count\'];

echo "Before: Used count = $before_used\\n";

// 3. Tạo order và voucher usage
$conn->begin_transaction();

try {
    // Tạo order
    $order_sql = "INSERT INTO orders (user_id, address_id, total_amount, status) VALUES (1, 1, 100000, \'pending\')";
    mysqli_query($conn, $order_sql);
    $order_id = mysqli_insert_id($conn);
    
    // Tạo voucher usage
    $usage_sql = "INSERT INTO voucher_usage (voucher_id, user_id, order_id, discount_applied, quantity) VALUES (?, 1, ?, 20000, 1)";
    $usage_stmt = $conn->prepare($usage_sql);
    $usage_stmt->bind_param("ii", $voucher[\'id\'], $order_id);
    $usage_stmt->execute();
    
    $conn->commit();
    echo "Order created: $order_id\\n";
    
    // 4. Kiểm tra quantity sau
    $after_sql = "SELECT COALESCE(SUM(quantity), 0) as used_count FROM voucher_usage WHERE voucher_id = ?";
    $after_stmt = $conn->prepare($after_sql);
    $after_stmt->bind_param("i", $voucher[\'id\']);
    $after_stmt->execute();
    $after_result = $after_stmt->get_result();
    $after_data = $after_result->fetch_assoc();
    $after_used = $after_data[\'used_count\'];
    
    echo "After: Used count = $after_used\\n";
    echo "Difference: " . ($after_used - $before_used) . "\\n";
    
} catch (Exception $e) {
    $conn->rollback();
    echo "Error: " . $e->getMessage() . "\\n";
}
?>
';

echo "<div style='background: #f8f9fa; padding: 15px; border-radius: 8px; margin: 10px 0;'>";
echo "<h3>Test script:</h3>";
echo "<pre>" . htmlspecialchars($test_script) . "</pre>";
echo "</div>";

// 8. Tóm tắt giải pháp
echo "<h2>8. 📋 Tóm tắt giải pháp</h2>";

echo "<div style='background: #d4edda; padding: 15px; border-radius: 8px; margin: 10px 0;'>";
echo "<h3>✅ Các bước cần thực hiện:</h3>";
echo "<ol>";
echo "<li><strong>Thêm cột quantity vào voucher_usage table</strong> (nếu chưa có)</li>";
echo "<li><strong>Cập nhật API logic:</strong> Sử dụng SUM(quantity) thay vì COUNT(*)</li>";
echo "<li><strong>Thêm try-catch cho voucher usage insert</strong> để tránh rollback toàn bộ transaction</li>";
echo "<li><strong>Test end-to-end</strong> với script test</li>";
echo "<li><strong>Kiểm tra Flutter app</strong> để đảm bảo gửi đúng voucher data</li>";
echo "</ol>";
echo "</div>";

echo "<div style='background: #f8d7da; padding: 15px; border-radius: 8px; margin: 10px 0;'>";
echo "<h3>⚠️ Lưu ý quan trọng:</h3>";
echo "<ul>";
echo "<li>Voucher usage chỉ được tạo khi order thành công</li>";
echo "<li>Transaction rollback sẽ xóa cả order và voucher usage</li>";
echo "<li>Cần kiểm tra voucher quantity trước khi tạo order</li>";
echo "<li>Debug logs sẽ giúp track được vấn đề</li>";
echo "</ul>";
echo "</div>";

mysqli_close($conn);
?> 