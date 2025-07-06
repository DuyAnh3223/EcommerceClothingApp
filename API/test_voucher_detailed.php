<?php
header('Content-Type: text/html; charset=utf-8');
require_once 'config/db_connect.php';

// Set timezone to Vietnam
date_default_timezone_set('Asia/Ho_Chi_Minh');

echo "<h1>🔍 Test Voucher Validation với Thông báo Chi tiết</h1>";

// Test cases
$testCases = [
    [
        'code' => 'GIAM20K',
        'product_ids' => [4, 6],
        'description' => 'Voucher hợp lệ'
    ],
    [
        'code' => 'INVALID_CODE',
        'product_ids' => [4, 6],
        'description' => 'Voucher không tồn tại'
    ],
    [
        'code' => 'EXPIRED_VOUCHER',
        'product_ids' => [4, 6],
        'description' => 'Voucher hết hiệu lực'
    ],
    [
        'code' => 'EMPTY_CODE',
        'product_ids' => [4, 6],
        'description' => 'Mã voucher trống'
    ]
];

foreach ($testCases as $testCase) {
    echo "<h2>🧪 Test: {$testCase['description']}</h2>";
    echo "<p><strong>Mã voucher:</strong> {$testCase['code']}</p>";
    echo "<p><strong>Sản phẩm:</strong> " . implode(', ', $testCase['product_ids']) . "</p>";
    
    // Simulate API call
    $input = [
        'voucher_code' => $testCase['code'],
        'product_ids' => $testCase['product_ids']
    ];
    
    try {
        // Get voucher details
        $voucherCode = mysqli_real_escape_string($conn, $input['voucher_code']);
        $productIds = array_map('intval', $input['product_ids']);
        $productIdsStr = implode(',', $productIds);
        
        // Get voucher details
        $voucherQuery = "
            SELECT 
                v.id,
                v.voucher_code,
                v.discount_amount,
                v.quantity,
                v.start_date,
                v.end_date,
                v.voucher_type,
                v.category_filter,
                COUNT(vu.id) as used_count
            FROM vouchers v
            LEFT JOIN voucher_usage vu ON v.id = vu.voucher_id
            WHERE v.voucher_code = '$voucherCode'
            GROUP BY v.id
        ";
        
        $voucherResult = mysqli_query($conn, $voucherQuery);
        
        if (!$voucherResult || mysqli_num_rows($voucherResult) === 0) {
            echo "<div style='background: #f8d7da; color: #721c24; padding: 10px; border-radius: 4px; margin: 10px 0;'>";
            echo "❌ <strong>Lỗi:</strong> Mã voucher không tồn tại";
            echo "</div>";
            continue;
        }
        
        $voucher = mysqli_fetch_assoc($voucherResult);
        
        // Check if voucher is valid
        $now = new DateTime();
        $startDate = new DateTime($voucher['start_date']);
        $endDate = new DateTime($voucher['end_date']);
        
        echo "<div style='background: #e7f3ff; padding: 10px; border-radius: 4px; margin: 10px 0;'>";
        echo "<strong>Thông tin voucher:</strong><br>";
        echo "- Mã: {$voucher['voucher_code']}<br>";
        echo "- Giảm giá: " . number_format($voucher['discount_amount']) . " VNĐ<br>";
        echo "- Số lượng: {$voucher['quantity']}<br>";
        echo "- Đã sử dụng: {$voucher['used_count']}<br>";
        echo "- Bắt đầu: " . $startDate->format('d/m/Y H:i') . "<br>";
        echo "- Kết thúc: " . $endDate->format('d/m/Y H:i') . "<br>";
        echo "- Thời gian hiện tại: " . $now->format('d/m/Y H:i') . "<br>";
        echo "</div>";
        
        // Check voucher validity period
        if ($now < $startDate) {
            $startDateFormatted = $startDate->format('d/m/Y H:i');
            echo "<div style='background: #fff3cd; color: #856404; padding: 10px; border-radius: 4px; margin: 10px 0;'>";
            echo "⏰ <strong>Lỗi:</strong> Voucher chưa có hiệu lực. Thời gian bắt đầu: $startDateFormatted";
            echo "</div>";
            continue;
        }
        
        if ($now > $endDate) {
            $endDateFormatted = $endDate->format('d/m/Y H:i');
            echo "<div style='background: #f8d7da; color: #721c24; padding: 10px; border-radius: 4px; margin: 10px 0;'>";
            echo "⏰ <strong>Lỗi:</strong> Voucher đã hết hiệu lực. Thời gian kết thúc: $endDateFormatted";
            echo "</div>";
            continue;
        }
        
        // Check if voucher has remaining quantity
        $remainingQuantity = $voucher['quantity'] - $voucher['used_count'];
        if ($remainingQuantity <= 0) {
            echo "<div style='background: #f8d7da; color: #721c24; padding: 10px; border-radius: 4px; margin: 10px 0;'>";
            echo "📦 <strong>Lỗi:</strong> Voucher đã hết số lượng sử dụng";
            echo "</div>";
            continue;
        }
        
        // Check voucher type and product applicability
        $applicableProducts = [];
        $totalDiscount = 0;
        
        switch ($voucher['voucher_type']) {
            case 'all_products':
                $applicableProducts = $productIds;
                $totalDiscount = $voucher['discount_amount'] * count($productIds);
                break;
                
            case 'specific_products':
                $assocQuery = "
                    SELECT product_id 
                    FROM voucher_product_associations 
                    WHERE voucher_id = {$voucher['id']} 
                    AND product_id IN ($productIdsStr)
                ";
                $assocResult = mysqli_query($conn, $assocQuery);
                
                while ($row = mysqli_fetch_assoc($assocResult)) {
                    $applicableProducts[] = $row['product_id'];
                }
                
                if (!empty($applicableProducts)) {
                    $totalDiscount = $voucher['discount_amount'] * count($applicableProducts);
                }
                break;
                
            case 'category_based':
                $categoryFilter = mysqli_real_escape_string($conn, $voucher['category_filter']);
                $categoryQuery = "
                    SELECT id 
                    FROM products 
                    WHERE id IN ($productIdsStr) 
                    AND category = '$categoryFilter'
                ";
                $categoryResult = mysqli_query($conn, $categoryQuery);
                
                while ($row = mysqli_fetch_assoc($categoryResult)) {
                    $applicableProducts[] = $row['id'];
                }
                
                if (!empty($applicableProducts)) {
                    $totalDiscount = $voucher['discount_amount'] * count($applicableProducts);
                }
                break;
                
            default:
                echo "<div style='background: #f8d7da; color: #721c24; padding: 10px; border-radius: 4px; margin: 10px 0;'>";
                echo "❌ <strong>Lỗi:</strong> Loại voucher không hợp lệ";
                echo "</div>";
                continue;
        }
        
        if (empty($applicableProducts)) {
            echo "<div style='background: #f8d7da; color: #721c24; padding: 10px; border-radius: 4px; margin: 10px 0;'>";
            echo "🚫 <strong>Lỗi:</strong> Voucher không áp dụng được cho sản phẩm đã chọn";
            echo "</div>";
            continue;
        }
        
        // Success case
        echo "<div style='background: #d4edda; color: #155724; padding: 10px; border-radius: 4px; margin: 10px 0;'>";
        echo "✅ <strong>Thành công:</strong> Voucher hợp lệ<br>";
        echo "- Tổng giảm giá: " . number_format($totalDiscount) . " VNĐ<br>";
        echo "- Sản phẩm áp dụng: " . implode(', ', $applicableProducts) . "<br>";
        echo "- Còn lại: $remainingQuantity lần sử dụng";
        echo "</div>";
        
    } catch (Exception $e) {
        echo "<div style='background: #f8d7da; color: #721c24; padding: 10px; border-radius: 4px; margin: 10px 0;'>";
        echo "❌ <strong>Lỗi hệ thống:</strong> " . $e->getMessage();
        echo "</div>";
    }
    
    echo "<hr>";
}

mysqli_close($conn);
?> 