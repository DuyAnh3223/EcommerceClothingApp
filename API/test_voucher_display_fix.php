<?php
header('Content-Type: text/html; charset=utf-8');
require_once 'config/db_connect.php';

// Set timezone to Vietnam
date_default_timezone_set('Asia/Ho_Chi_Minh');

echo "<h1>🧪 Test Voucher Display Fix</h1>";

// 1. Test API get_vouchers.php
echo "<h2>1. 📊 Test API get_vouchers.php</h2>";

$vouchers_sql = "
    SELECT 
        v.id,
        v.voucher_code,
        v.discount_amount,
        v.quantity as original_quantity,
        v.start_date,
        v.end_date,
        v.voucher_type,
        v.category_filter,
        COUNT(vu.id) as used_count,
        (v.quantity - COUNT(vu.id)) as remaining_quantity
    FROM vouchers v
    LEFT JOIN voucher_usage vu ON v.id = vu.voucher_id
    GROUP BY v.id
    ORDER BY v.id DESC
    LIMIT 5
";

$vouchers_result = mysqli_query($conn, $vouchers_sql);

if ($vouchers_result) {
    echo "<table border='1' style='border-collapse: collapse; width: 100%; margin: 10px 0;'>";
    echo "<tr style='background: #f0f0f0;'>";
    echo "<th>ID</th><th>Mã Voucher</th><th>Original Quantity</th><th>Used Count</th><th>Remaining Quantity</th><th>Status</th>";
    echo "</tr>";
    
    while ($voucher = mysqli_fetch_assoc($vouchers_result)) {
        $status_color = $voucher['remaining_quantity'] > 0 ? 'green' : 'red';
        $status_text = $voucher['remaining_quantity'] > 0 ? '🟢 Available' : '🔴 Exhausted';
        
        echo "<tr>";
        echo "<td>{$voucher['id']}</td>";
        echo "<td><strong>{$voucher['voucher_code']}</strong></td>";
        echo "<td>{$voucher['original_quantity']}</td>";
        echo "<td>{$voucher['used_count']}</td>";
        echo "<td style='color: $status_color; font-weight: bold;'>{$voucher['remaining_quantity']}</td>";
        echo "<td>$status_text</td>";
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "<p style='color: red;'>❌ Lỗi truy vấn: " . mysqli_error($conn) . "</p>";
}

// 2. Test Flutter app sẽ nhận được data gì
echo "<h2>2. 📱 Test Flutter app sẽ nhận được data</h2>";

$test_voucher_sql = "SELECT v.id, v.voucher_code, v.quantity as original_quantity, 
                            COUNT(vu.id) as used_count, 
                            (v.quantity - COUNT(vu.id)) as remaining_quantity 
                     FROM vouchers v 
                     LEFT JOIN voucher_usage vu ON v.id = vu.voucher_id 
                     WHERE v.voucher_code = 'GIAM20K' 
                     GROUP BY v.id";

$test_result = mysqli_query($conn, $test_voucher_sql);

if ($test_result && mysqli_num_rows($test_result) > 0) {
    $test_voucher = mysqli_fetch_assoc($test_result);
    
    echo "<div style='background: #e7f3ff; padding: 15px; border-radius: 8px; margin: 10px 0;'>";
    echo "<h3>Test Voucher: {$test_voucher['voucher_code']}</h3>";
    echo "<p><strong>Original Quantity:</strong> {$test_voucher['original_quantity']}</p>";
    echo "<p><strong>Used Count:</strong> {$test_voucher['used_count']}</p>";
    echo "<p><strong>Remaining Quantity:</strong> {$test_voucher['remaining_quantity']}</p>";
    
    // Simulate API response
    $api_response = [
        'id' => (int)$test_voucher['id'],
        'voucher_code' => $test_voucher['voucher_code'],
        'discount_amount' => 20000,
        'quantity' => (int)$test_voucher['original_quantity'],
        'used_count' => (int)$test_voucher['used_count'],
        'remaining_quantity' => (int)$test_voucher['remaining_quantity'],
        'start_date' => '2024-01-01 00:00:00',
        'end_date' => '2025-12-31 23:59:59',
        'voucher_type' => 'all_products',
        'category_filter' => null,
        'associated_product_ids' => null,
        'created_at' => '2024-01-01 00:00:00',
        'updated_at' => '2024-01-01 00:00:00'
    ];
    
    echo "<h4>API Response (JSON):</h4>";
    echo "<pre>" . json_encode($api_response, JSON_PRETTY_PRINT) . "</pre>";
    echo "</div>";
}

// 3. Test Voucher model parsing
echo "<h2>3. 🔧 Test Voucher Model Parsing</h2>";

echo "<div style='background: #fff3cd; padding: 15px; border-radius: 8px; margin: 10px 0;'>";
echo "<h3>Flutter Voucher.fromJson() sẽ parse:</h3>";
echo "<ul>";
echo "<li><strong>originalQuantity:</strong> " . ($api_response['quantity'] ?? 'N/A') . "</li>";
echo "<li><strong>usedCount:</strong> " . ($api_response['used_count'] ?? 'N/A') . "</li>";
echo "<li><strong>remainingQuantity:</strong> " . ($api_response['remaining_quantity'] ?? 'N/A') . "</li>";
echo "<li><strong>hasQuantity:</strong> " . (($api_response['remaining_quantity'] ?? 0) > 0 ? 'true' : 'false') . "</li>";
echo "<li><strong>canUse:</strong> " . (($api_response['remaining_quantity'] ?? 0) > 0 ? 'true' : 'false') . "</li>";
echo "</ul>";
echo "</div>";

// 4. Test display widget
echo "<h2>4. 📱 Test Display Widget</h2>";

echo "<div style='background: #d1ecf1; padding: 15px; border-radius: 8px; margin: 10px 0;'>";
echo "<h3>VoucherDisplayWidget sẽ hiển thị:</h3>";
echo "<p><strong>Trước khi fix:</strong> Số lượng: " . ($api_response['quantity'] ?? 'N/A') . "</p>";
echo "<p><strong>Sau khi fix:</strong> Số lượng: " . ($api_response['remaining_quantity'] ?? 'N/A') . " (còn lại) / " . ($api_response['quantity'] ?? 'N/A') . " (tổng)</p>";
echo "</div>";

// 5. Kết luận
echo "<h2>5. 📋 Kết luận</h2>";

echo "<div style='background: #d4edda; padding: 15px; border-radius: 8px; margin: 10px 0;'>";
echo "<h3>✅ Fix đã được thực hiện:</h3>";
echo "<ul>";
echo "<li><strong>API get_vouchers.php:</strong> Trả về remaining_quantity thay vì chỉ original_quantity</li>";
echo "<li><strong>Flutter Voucher model:</strong> Thêm usedCount và remainingQuantity fields</li>";
echo "<li><strong>VoucherDisplayWidget:</strong> Hiển thị remaining_quantity thay vì original_quantity</li>";
echo "<li><strong>VoucherInputWidget:</strong> Đã đúng - hiển thị remainingQuantity</li>";
echo "</ul>";
echo "</div>";

echo "<div style='background: #f8d7da; padding: 15px; border-radius: 8px; margin: 10px 0;'>";
echo "<h3>⚠️ Lưu ý:</h3>";
echo "<ul>";
echo "<li>Cần test lại Flutter app sau khi deploy API fix</li>";
echo "<li>Voucher quantity sẽ hiển thị chính xác: còn lại / tổng</li>";
echo "<li>User sẽ thấy voucher quantity giảm khi sử dụng</li>";
echo "</ul>";
echo "</div>";

mysqli_close($conn);
?> 