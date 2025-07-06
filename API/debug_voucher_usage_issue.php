<?php
header('Content-Type: text/html; charset=utf-8');
require_once 'config/db_connect.php';

// Set timezone to Vietnam
date_default_timezone_set('Asia/Ho_Chi_Minh');

echo "<h1>🔍 Debug Voucher Usage Issues</h1>";

// 1. Kiểm tra cấu trúc bảng voucher_usage
echo "<h2>1. 📋 Kiểm tra cấu trúc bảng voucher_usage</h2>";

$structure_sql = "DESCRIBE voucher_usage";
$structure_result = mysqli_query($conn, $structure_sql);

if ($structure_result) {
    echo "<table border='1' style='border-collapse: collapse; width: 100%; margin: 10px 0;'>";
    echo "<tr style='background: #f0f0f0;'><th>Field</th><th>Type</th><th>Null</th><th>Key</th><th>Default</th><th>Extra</th></tr>";
    
    while ($field = mysqli_fetch_assoc($structure_result)) {
        echo "<tr>";
        echo "<td>{$field['Field']}</td>";
        echo "<td>{$field['Type']}</td>";
        echo "<td>{$field['Null']}</td>";
        echo "<td>{$field['Key']}</td>";
        echo "<td>{$field['Default']}</td>";
        echo "<td>{$field['Extra']}</td>";
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "<p style='color: red;'>❌ Lỗi kiểm tra cấu trúc: " . mysqli_error($conn) . "</p>";
}

// 2. Kiểm tra voucher usage records hiện tại
echo "<h2>2. 📊 Kiểm tra voucher usage records</h2>";

$usage_sql = "
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
    ORDER BY vu.used_at DESC
    LIMIT 10
";

$usage_result = mysqli_query($conn, $usage_sql);

if ($usage_result && mysqli_num_rows($usage_result) > 0) {
    echo "<table border='1' style='border-collapse: collapse; width: 100%; margin: 10px 0;'>";
    echo "<tr style='background: #f0f0f0;'>";
    echo "<th>ID</th><th>Voucher ID</th><th>Mã Voucher</th><th>User</th><th>Order ID</th><th>Order Status</th><th>Discount</th><th>Used At</th>";
    echo "</tr>";
    
    while ($usage = mysqli_fetch_assoc($usage_result)) {
        $status_color = $usage['order_status'] === 'confirmed' ? 'green' : 'orange';
        echo "<tr>";
        echo "<td>{$usage['id']}</td>";
        echo "<td>{$usage['voucher_id']}</td>";
        echo "<td><strong>{$usage['voucher_code']}</strong></td>";
        echo "<td>{$usage['username']}</td>";
        echo "<td>#{$usage['order_id']}</td>";
        echo "<td style='color: $status_color;'>{$usage['order_status']}</td>";
        echo "<td>" . number_format($usage['discount_applied']) . " VNĐ</td>";
        echo "<td>" . date('d/m/Y H:i:s', strtotime($usage['used_at'])) . "</td>";
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "<p style='color: orange;'>⚠️ Chưa có voucher usage records nào</p>";
}

// 3. Kiểm tra logic tính used_count
echo "<h2>3. 🧮 Kiểm tra logic tính used_count</h2>";

$vouchers_sql = "
    SELECT 
        v.id,
        v.voucher_code,
        v.quantity,
        COUNT(vu.id) as used_count,
        (v.quantity - COUNT(vu.id)) as remaining_quantity
    FROM vouchers v
    LEFT JOIN voucher_usage vu ON v.id = vu.voucher_id
    GROUP BY v.id
    ORDER BY v.id DESC
";

$vouchers_result = mysqli_query($conn, $vouchers_sql);

if ($vouchers_result) {
    echo "<table border='1' style='border-collapse: collapse; width: 100%; margin: 10px 0;'>";
    echo "<tr style='background: #f0f0f0;'>";
    echo "<th>ID</th><th>Mã Voucher</th><th>Tổng Quantity</th><th>Used Count</th><th>Remaining</th><th>Status</th>";
    echo "</tr>";
    
    while ($voucher = mysqli_fetch_assoc($vouchers_result)) {
        $status_color = $voucher['remaining_quantity'] > 0 ? 'green' : 'red';
        $status_text = $voucher['remaining_quantity'] > 0 ? '🟢 Available' : '🔴 Exhausted';
        
        echo "<tr>";
        echo "<td>{$voucher['id']}</td>";
        echo "<td><strong>{$voucher['voucher_code']}</strong></td>";
        echo "<td>{$voucher['quantity']}</td>";
        echo "<td>{$voucher['used_count']}</td>";
        echo "<td style='color: $status_color; font-weight: bold;'>{$voucher['remaining_quantity']}</td>";
        echo "<td>$status_text</td>";
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "<p style='color: red;'>❌ Lỗi truy vấn: " . mysqli_error($conn) . "</p>";
}

// 4. Kiểm tra transaction logs
echo "<h2>4. 📝 Kiểm tra transaction logs</h2>";

// Kiểm tra error logs
$log_file = ini_get('error_log');
if ($log_file && file_exists($log_file)) {
    echo "<h3>Error Log (last 20 lines):</h3>";
    echo "<div style='background: #f5f5f5; padding: 10px; border-radius: 5px; font-family: monospace; font-size: 12px; max-height: 300px; overflow-y: auto;'>";
    
    $log_lines = file($log_file);
    $recent_lines = array_slice($log_lines, -20);
    
    foreach ($recent_lines as $line) {
        if (strpos($line, 'DEBUG ORDER') !== false || strpos($line, 'voucher') !== false) {
            echo htmlspecialchars($line) . "<br>";
        }
    }
    echo "</div>";
} else {
    echo "<p style='color: orange;'>⚠️ Không tìm thấy error log file</p>";
}

// 5. Test tạo voucher usage record
echo "<h2>5. 🧪 Test tạo voucher usage record</h2>";

$test_voucher_sql = "SELECT id, voucher_code, quantity FROM vouchers WHERE voucher_code = 'GIAM20K' LIMIT 1";
$test_voucher_result = mysqli_query($conn, $test_voucher_sql);

if ($test_voucher_result && mysqli_num_rows($test_voucher_result) > 0) {
    $test_voucher = mysqli_fetch_assoc($test_voucher_result);
    
    // Lấy user_id thực tế từ database
    $user_sql = "SELECT id, username FROM users LIMIT 1";
    $user_result = mysqli_query($conn, $user_sql);
    
    if ($user_result && mysqli_num_rows($user_result) > 0) {
        $user_data = mysqli_fetch_assoc($user_result);
        $test_user_id = $user_data['id'];
        
        echo "<div style='background: #e7f3ff; padding: 15px; border-radius: 8px; margin: 10px 0;'>";
        echo "<h3>Test Voucher: {$test_voucher['voucher_code']}</h3>";
        echo "<p><strong>ID:</strong> {$test_voucher['id']}</p>";
        echo "<p><strong>Quantity:</strong> {$test_voucher['quantity']}</p>";
        echo "<p><strong>Test User:</strong> {$user_data['username']} (ID: {$test_user_id})</p>";
        
        // Test insert voucher usage
        $test_order_id = 999; // Order ID test
        $test_discount = 20000;
        
        $insert_sql = "INSERT INTO voucher_usage (voucher_id, user_id, order_id, discount_applied) VALUES (?, ?, ?, ?)";
        $insert_stmt = $conn->prepare($insert_sql);
        $insert_stmt->bind_param("iiid", $test_voucher['id'], $test_user_id, $test_order_id, $test_discount);
        
        if ($insert_stmt->execute()) {
            echo "<p style='color: green;'>✅ Test insert voucher usage thành công!</p>";
            
            // Kiểm tra lại voucher quantity
            $check_sql = "
                SELECT 
                    v.quantity,
                    COUNT(vu.id) as used_count,
                    (v.quantity - COUNT(vu.id)) as remaining_quantity
                FROM vouchers v
                LEFT JOIN voucher_usage vu ON v.id = vu.voucher_id
                WHERE v.id = ?
                GROUP BY v.id
            ";
            $check_stmt = $conn->prepare($check_sql);
            $check_stmt->bind_param("i", $test_voucher['id']);
            $check_stmt->execute();
            $check_result = $check_stmt->get_result();
            $check_data = $check_result->fetch_assoc();
            
            echo "<p><strong>Sau khi insert:</strong></p>";
            echo "<p>- Total Quantity: {$check_data['quantity']}</p>";
            echo "<p>- Used Count: {$check_data['used_count']}</p>";
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
        echo "<p style='color: red;'>❌ Không tìm thấy user nào trong database</p>";
    }
} else {
    echo "<p style='color: red;'>❌ Không tìm thấy voucher GIAM20K để test</p>";
}

// 6. Kiểm tra transaction isolation
echo "<h2>6. 🔄 Kiểm tra transaction isolation</h2>";

$isolation_sql = "SELECT @@tx_isolation, @@autocommit";
$isolation_result = mysqli_query($conn, $isolation_sql);

if ($isolation_result) {
    $isolation_data = mysqli_fetch_assoc($isolation_result);
    echo "<div style='background: #fff3cd; padding: 15px; border-radius: 8px; margin: 10px 0;'>";
    echo "<p><strong>Transaction Isolation Level:</strong> {$isolation_data['@@tx_isolation']}</p>";
    echo "<p><strong>Autocommit:</strong> {$isolation_data['@@autocommit']}</p>";
    echo "</div>";
}

// 7. Tóm tắt vấn đề
echo "<h2>7. 📋 Tóm tắt vấn đề</h2>";

echo "<div style='background: #f8d7da; padding: 15px; border-radius: 8px; margin: 10px 0;'>";
echo "<h3>🔍 Các vấn đề có thể xảy ra:</h3>";
echo "<ul>";
echo "<li><strong>Voucher usage records không được tạo:</strong> Kiểm tra xem có lỗi INSERT không</li>";
echo "<li><strong>Logic tính used_count:</strong> Đảm bảo COUNT(voucher_usage) hoạt động đúng</li>";
echo "<li><strong>Transaction rollback:</strong> Kiểm tra có exception nào khiến transaction bị rollback</li>";
echo "<li><strong>Voucher data không được gửi từ Flutter:</strong> Kiểm tra voucher_id, discount_amount</li>";
echo "<li><strong>Order status:</strong> Voucher usage chỉ được tạo khi order thành công</li>";
echo "</ul>";
echo "</div>";

echo "<h2>8. 🛠️ Giải pháp đề xuất</h2>";

echo "<div style='background: #d1ecf1; padding: 15px; border-radius: 8px; margin: 10px 0;'>";
echo "<h3>✅ Các bước debug:</h3>";
echo "<ol>";
echo "<li>Kiểm tra Flutter app logs để đảm bảo voucher data được gửi đúng</li>";
echo "<li>Kiểm tra API error logs để tìm lỗi transaction</li>";
echo "<li>Test với Postman để isolate frontend/backend issues</li>";
echo "<li>Thêm debug logs chi tiết trong place_order_with_combinations.php</li>";
echo "<li>Kiểm tra order status trước khi tạo voucher usage</li>";
echo "</ol>";
echo "</div>";

mysqli_close($conn);
?> 