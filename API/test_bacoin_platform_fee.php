<?php
// Test script để kiểm tra platform_fee cho BACoin
require_once 'config/db_connect.php';

echo "=== TEST BACOIN PLATFORM FEE ===\n\n";

// 1. Tạo đơn hàng test với BACoin
echo "1. Tạo đơn hàng test với BACoin...\n";

$test_data = [
    'user_id' => 4,
    'address_id' => 3,
    'payment_method' => 'BACoin',
    'cart_items' => [
        [
            'type' => 'product',
            'product_id' => 31, // Quần lửng (agency product)
            'variant_id' => 27,
            'quantity' => 1
        ]
    ]
];

// Gọi API đặt hàng
$url = 'http://localhost/EcommerceClothingApp/API/orders/place_order_with_combinations.php';
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($test_data));
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Accept: application/json'
]);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

$response = curl_exec($ch);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "HTTP Code: $http_code\n";
echo "Response: $response\n\n";

$result = json_decode($response, true);

if ($result && isset($result['success']) && $result['success']) {
    $order_id = $result['order_id'];
    echo "✅ Đơn hàng được tạo thành công: #$order_id\n\n";
    
    // 2. Kiểm tra dữ liệu trong database
    echo "2. Kiểm tra dữ liệu trong database...\n";
    
    $order_sql = "SELECT id, user_id, total_amount, total_amount_bacoin, platform_fee, status, voucher_id 
                   FROM orders WHERE id = ?";
    $order_stmt = $conn->prepare($order_sql);
    $order_stmt->bind_param("i", $order_id);
    $order_stmt->execute();
    $order_result = $order_stmt->get_result();
    
    if ($order_result->num_rows > 0) {
        $order_data = $order_result->fetch_assoc();
        echo "📋 Thông tin đơn hàng:\n";
        echo "- ID: " . $order_data['id'] . "\n";
        echo "- User ID: " . $order_data['user_id'] . "\n";
        echo "- total_amount: " . ($order_data['total_amount'] ?? 'NULL') . "\n";
        echo "- total_amount_bacoin: " . ($order_data['total_amount_bacoin'] ?? 'NULL') . "\n";
        echo "- platform_fee: " . ($order_data['platform_fee'] ?? 'NULL') . "\n";
        echo "- status: " . $order_data['status'] . "\n";
        echo "- voucher_id: " . ($order_data['voucher_id'] ?? 'NULL') . "\n\n";
        
        // Kiểm tra logic
        $expected_bacoin = 60000; // Tổng tiền BACoin bao gồm cả platform_fee
        $expected_platform_fee = 10000; // 20% của 50000
        
        echo "🔍 Kiểm tra logic:\n";
        echo "- Expected total_amount: 0 (cho BACoin)\n";
        echo "- Expected total_amount_bacoin: $expected_bacoin (bao gồm cả platform_fee)\n";
        echo "- Expected platform_fee: $expected_platform_fee\n";
        echo "- Giá gốc sản phẩm: " . ($expected_bacoin - $expected_platform_fee) . " BACoin\n\n";
        
        if ($order_data['total_amount'] == 0 && 
            $order_data['total_amount_bacoin'] == $expected_bacoin && 
            $order_data['platform_fee'] == $expected_platform_fee) {
            echo "✅ TẤT CẢ ĐÚNG! Platform fee đã được lưu đúng cho BACoin\n";
        } else {
            echo "❌ CÓ LỖI! Dữ liệu không khớp:\n";
            if ($order_data['total_amount'] != 0) {
                echo "- total_amount phải = 0, nhưng = " . $order_data['total_amount'] . "\n";
            }
            if ($order_data['total_amount_bacoin'] != $expected_bacoin) {
                echo "- total_amount_bacoin phải = $expected_bacoin, nhưng = " . $order_data['total_amount_bacoin'] . "\n";
            }
            if ($order_data['platform_fee'] != $expected_platform_fee) {
                echo "- platform_fee phải = $expected_platform_fee, nhưng = " . $order_data['platform_fee'] . "\n";
            }
        }
        
    } else {
        echo "❌ Không tìm thấy đơn hàng trong database\n";
    }
    $order_stmt->close();
    
    // 3. Kiểm tra order_items
    echo "\n3. Kiểm tra order_items...\n";
    
    $items_sql = "SELECT oi.product_id, oi.variant_id, oi.quantity, oi.price, oi.platform_fee,
                          p.name as product_name, p.is_agency_product, p.platform_fee_rate
                   FROM order_items oi
                   JOIN products p ON oi.product_id = p.id
                   WHERE oi.order_id = ?";
    $items_stmt = $conn->prepare($items_sql);
    $items_stmt->bind_param("i", $order_id);
    $items_stmt->execute();
    $items_result = $items_stmt->get_result();
    
    while ($item = $items_result->fetch_assoc()) {
        echo "📦 Sản phẩm: " . $item['product_name'] . "\n";
        echo "- Product ID: " . $item['product_id'] . "\n";
        echo "- Variant ID: " . $item['variant_id'] . "\n";
        echo "- Quantity: " . $item['quantity'] . "\n";
        echo "- Price: " . $item['price'] . "\n";
        echo "- Platform Fee: " . $item['platform_fee'] . "\n";
        echo "- Is Agency Product: " . ($item['is_agency_product'] ? 'Yes' : 'No') . "\n";
        echo "- Platform Fee Rate: " . $item['platform_fee_rate'] . "%\n\n";
    }
    $items_stmt->close();
    
    // 4. Kiểm tra payment
    echo "4. Kiểm tra payment...\n";
    
    $payment_sql = "SELECT id, order_id, payment_method, amount, amount_bacoin, status, transaction_code
                    FROM payments WHERE order_id = ?";
    $payment_stmt = $conn->prepare($payment_sql);
    $payment_stmt->bind_param("i", $order_id);
    $payment_stmt->execute();
    $payment_result = $payment_stmt->get_result();
    
    if ($payment_result->num_rows > 0) {
        $payment_data = $payment_result->fetch_assoc();
        echo "💳 Thông tin thanh toán:\n";
        echo "- Payment ID: " . $payment_data['id'] . "\n";
        echo "- Order ID: " . $payment_data['order_id'] . "\n";
        echo "- Payment Method: " . $payment_data['payment_method'] . "\n";
        echo "- Amount: " . ($payment_data['amount'] ?? 'NULL') . "\n";
        echo "- Amount BACoin: " . ($payment_data['amount_bacoin'] ?? 'NULL') . "\n";
        echo "- Status: " . $payment_data['status'] . "\n";
        echo "- Transaction Code: " . ($payment_data['transaction_code'] ?? 'NULL') . "\n\n";
    } else {
        echo "❌ Không tìm thấy payment record\n";
    }
    $payment_stmt->close();
    
} else {
    echo "❌ Lỗi tạo đơn hàng:\n";
    if (isset($result['message'])) {
        echo "- Message: " . $result['message'] . "\n";
    }
    if (isset($result['debug_info'])) {
        echo "- Debug Info: " . json_encode($result['debug_info']) . "\n";
    }
}

$conn->close();
echo "\n=== KẾT THÚC TEST ===\n";
?> 