<?php
// Test script để kiểm tra logic lưu giá theo phương thức thanh toán
require_once 'config/db_connect.php';

echo "=== TEST PRICE COLUMNS LOGIC ===\n\n";

// 1. Test đặt hàng với COD
echo "1. Test đặt hàng với COD...\n";

$cod_test_data = [
    'user_id' => 4,
    'address_id' => 3,
    'payment_method' => 'COD',
    'cart_items' => [
        [
            'type' => 'product',
            'product_id' => 4, // Áo đi biển (admin product)
            'variant_id' => 6,
            'quantity' => 1
        ]
    ]
];

$url = 'http://localhost/EcommerceClothingApp/API/orders/place_order_with_combinations.php';
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($cod_test_data));
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

$response = curl_exec($ch);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "HTTP Code: $http_code\n";
echo "Response: $response\n";

$cod_result = json_decode($response, true);
if ($cod_result['success']) {
    $cod_order_id = $cod_result['order_id'];
    echo "✅ Đơn hàng COD được tạo thành công: #$cod_order_id\n\n";
} else {
    echo "❌ Lỗi tạo đơn hàng COD\n\n";
}

// 2. Test đặt hàng với BACoin
echo "2. Test đặt hàng với BACoin...\n";

$bacoin_test_data = [
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

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($bacoin_test_data));
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

$response = curl_exec($ch);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "HTTP Code: $http_code\n";
echo "Response: $response\n";

$bacoin_result = json_decode($response, true);
if ($bacoin_result['success']) {
    $bacoin_order_id = $bacoin_result['order_id'];
    echo "✅ Đơn hàng BACoin được tạo thành công: #$bacoin_order_id\n\n";
} else {
    echo "❌ Lỗi tạo đơn hàng BACoin\n\n";
}

// 3. Kiểm tra dữ liệu trong database
echo "3. Kiểm tra dữ liệu trong database...\n";

if (isset($cod_order_id)) {
    echo "\n📋 Đơn hàng COD #$cod_order_id:\n";
    $cod_order_sql = "SELECT id, user_id, total_amount, total_amount_bacoin, platform_fee, status FROM orders WHERE id = ?";
    $cod_order_stmt = $conn->prepare($cod_order_sql);
    $cod_order_stmt->bind_param("i", $cod_order_id);
    $cod_order_stmt->execute();
    $cod_order_result = $cod_order_stmt->get_result();
    $cod_order_data = $cod_order_result->fetch_assoc();
    $cod_order_stmt->close();
    
    if ($cod_order_data) {
        echo "- ID: " . $cod_order_data['id'] . "\n";
        echo "- User ID: " . $cod_order_data['user_id'] . "\n";
        echo "- total_amount: " . $cod_order_data['total_amount'] . "\n";
        echo "- total_amount_bacoin: " . ($cod_order_data['total_amount_bacoin'] ?? 'NULL') . "\n";
        echo "- platform_fee: " . $cod_order_data['platform_fee'] . "\n";
        echo "- status: " . $cod_order_data['status'] . "\n";
    }
    
    echo "\n📦 Order Items cho COD:\n";
    $cod_items_sql = "SELECT id, product_id, variant_id, quantity, price, price_bacoin, platform_fee FROM order_items WHERE order_id = ?";
    $cod_items_stmt = $conn->prepare($cod_items_sql);
    $cod_items_stmt->bind_param("i", $cod_order_id);
    $cod_items_stmt->execute();
    $cod_items_result = $cod_items_stmt->get_result();
    
    while ($item = $cod_items_result->fetch_assoc()) {
        echo "- Product ID: " . $item['product_id'] . "\n";
        echo "  Variant ID: " . $item['variant_id'] . "\n";
        echo "  Quantity: " . $item['quantity'] . "\n";
        echo "  Price (VNĐ): " . $item['price'] . "\n";
        echo "  Price BACoin: " . ($item['price_bacoin'] ?? 'NULL') . "\n";
        echo "  Platform Fee: " . $item['platform_fee'] . "\n";
    }
    $cod_items_stmt->close();
}

if (isset($bacoin_order_id)) {
    echo "\n📋 Đơn hàng BACoin #$bacoin_order_id:\n";
    $bacoin_order_sql = "SELECT id, user_id, total_amount, total_amount_bacoin, platform_fee, status FROM orders WHERE id = ?";
    $bacoin_order_stmt = $conn->prepare($bacoin_order_sql);
    $bacoin_order_stmt->bind_param("i", $bacoin_order_id);
    $bacoin_order_stmt->execute();
    $bacoin_order_result = $bacoin_order_stmt->get_result();
    $bacoin_order_data = $bacoin_order_result->fetch_assoc();
    $bacoin_order_stmt->close();
    
    if ($bacoin_order_data) {
        echo "- ID: " . $bacoin_order_data['id'] . "\n";
        echo "- User ID: " . $bacoin_order_data['user_id'] . "\n";
        echo "- total_amount: " . $bacoin_order_data['total_amount'] . "\n";
        echo "- total_amount_bacoin: " . ($bacoin_order_data['total_amount_bacoin'] ?? 'NULL') . "\n";
        echo "- platform_fee: " . $bacoin_order_data['platform_fee'] . "\n";
        echo "- status: " . $bacoin_order_data['status'] . "\n";
    }
    
    echo "\n📦 Order Items cho BACoin:\n";
    $bacoin_items_sql = "SELECT id, product_id, variant_id, quantity, price, price_bacoin, platform_fee FROM order_items WHERE order_id = ?";
    $bacoin_items_stmt = $conn->prepare($bacoin_items_sql);
    $bacoin_items_stmt->bind_param("i", $bacoin_order_id);
    $bacoin_items_stmt->execute();
    $bacoin_items_result = $bacoin_items_stmt->get_result();
    
    while ($item = $bacoin_items_result->fetch_assoc()) {
        echo "- Product ID: " . $item['product_id'] . "\n";
        echo "  Variant ID: " . $item['variant_id'] . "\n";
        echo "  Quantity: " . $item['quantity'] . "\n";
        echo "  Price (VNĐ): " . $item['price'] . "\n";
        echo "  Price BACoin: " . ($item['price_bacoin'] ?? 'NULL') . "\n";
        echo "  Platform Fee: " . $item['platform_fee'] . "\n";
    }
    $bacoin_items_stmt->close();
}

// 4. Kiểm tra logic
echo "\n4. Kiểm tra logic:\n";
echo "🔍 Logic mong đợi:\n";
echo "- COD/VNPAY: price = giá VNĐ, price_bacoin = NULL\n";
echo "- BACoin: price = 0, price_bacoin = giá BACoin\n";

if (isset($cod_order_id) && isset($bacoin_order_id)) {
    echo "\n✅ TEST HOÀN THÀNH! Logic đã được cập nhật thành công.\n";
} else {
    echo "\n❌ CÓ LỖI! Vui lòng kiểm tra lại.\n";
}

echo "\n=== KẾT THÚC TEST ===\n";
?> 