<?php
header('Content-Type: application/json');

require_once '../config/db_connect.php';

echo "=== Test place_order_multi.php với Platform Fee ===\n\n";

try {
    // 1. Tìm sản phẩm agency để test
    $product_query = "
        SELECT 
            p.id as product_id, p.name, p.is_agency_product, p.platform_fee_rate,
            pv.variant_id, pv.price, pv.stock
        FROM products p
        JOIN product_variant pv ON p.id = pv.product_id
        WHERE p.is_agency_product = 1 AND p.status = 'active' AND pv.status = 'active'
        LIMIT 1
    ";
    
    $product_result = $conn->query($product_query);
    
    if ($product_result->num_rows === 0) {
        echo "❌ Không tìm thấy sản phẩm agency active nào!\n";
        exit();
    }
    
    $product = $product_result->fetch_assoc();
    $product_id = $product['product_id'];
    $variant_id = $product['variant_id'];
    $base_price = $product['price'];
    $platform_fee_rate = $product['platform_fee_rate'];
    $platform_fee = $base_price * ($platform_fee_rate / 100);
    $final_price = $base_price + $platform_fee;
    
    echo "=== Thông tin sản phẩm sẽ test ===\n";
    echo "Product ID: $product_id\n";
    echo "Product Name: {$product['name']}\n";
    echo "Variant ID: $variant_id\n";
    echo "Base Price: $base_price VND\n";
    echo "Platform Fee Rate: $platform_fee_rate%\n";
    echo "Platform Fee: $platform_fee VND\n";
    echo "Final Price: $final_price VND\n";
    
    // 2. Tạo order data
    $order_data = [
        'user_id' => 4,
        'address_id' => 3,
        'payment_method' => 'COD',
        'items' => [
            [
                'product_id' => $product_id,
                'variant_id' => $variant_id,
                'quantity' => 2
            ]
        ]
    ];
    
    echo "\n=== Order Data ===\n";
    echo json_encode($order_data, JSON_PRETTY_PRINT) . "\n";
    
    // 3. Tính toán expected values
    $expected_total = $final_price * 2; // 2 items
    $expected_platform_fee = $platform_fee * 2;
    
    echo "\n=== Expected Results ===\n";
    echo "Expected Total Amount: $expected_total VND\n";
    echo "Expected Platform Fee: $expected_platform_fee VND\n";
    
    // 4. Gọi API place_order_multi
    echo "\n=== Gọi API place_order_multi ===\n";
    
    $url = 'http://localhost/EcommerceClothingApp/API/orders/place_order_multi.php';
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($order_data));
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json',
        'Accept: application/json'
    ]);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    
    $response = curl_exec($ch);
    $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    echo "HTTP Code: $http_code\n";
    echo "Response: $response\n";
    
    // 5. Parse response
    $response_data = json_decode($response, true);
    
    if ($response_data && $response_data['success']) {
        echo "\n✅ Order được tạo thành công!\n";
        echo "Order ID: {$response_data['order_id']}\n";
        
        // 6. Kiểm tra order trong database
        echo "\n=== Kiểm tra Order trong Database ===\n";
        $order_check_query = "
            SELECT o.*, oi.*
            FROM orders o
            JOIN order_items oi ON o.id = oi.order_id
            WHERE o.id = ?
        ";
        $order_check_stmt = $conn->prepare($order_check_query);
        $order_check_stmt->bind_param("i", $response_data['order_id']);
        $order_check_stmt->execute();
        $order_check_result = $order_check_stmt->get_result();
        
        $order_data = null;
        $item_data = null;
        
        while ($order_row = $order_check_result->fetch_assoc()) {
            if ($order_data === null) {
                $order_data = [
                    'id' => $order_row['id'],
                    'total_amount' => $order_row['total_amount'],
                    'platform_fee' => $order_row['platform_fee']
                ];
            }
            $item_data = [
                'price' => $order_row['price'],
                'item_platform_fee' => $order_row['platform_fee']
            ];
        }
        
        if ($order_data) {
            echo "Order ID: {$order_data['id']}\n";
            echo "Total Amount: {$order_data['total_amount']} VND\n";
            echo "Platform Fee: {$order_data['platform_fee']} VND\n";
            if ($item_data) {
                echo "Item Price: {$item_data['price']} VND\n";
                echo "Item Platform Fee: {$item_data['item_platform_fee']} VND\n";
            }
        }
        
        // 7. So sánh expected vs actual
        echo "\n=== So sánh Expected vs Actual ===\n";
        $actual_total = $order_data['total_amount'] ?? 0;
        $actual_platform_fee = $order_data['platform_fee'] ?? 0;
        
        echo "Expected Total: $expected_total VND\n";
        echo "Actual Total: $actual_total VND\n";
        echo "Match: " . ($expected_total == $actual_total ? "✅" : "❌") . "\n";
        
        echo "Expected Platform Fee: $expected_platform_fee VND\n";
        echo "Actual Platform Fee: $actual_platform_fee VND\n";
        echo "Match: " . ($expected_platform_fee == $actual_platform_fee ? "✅" : "❌") . "\n";
        
    } else {
        echo "\n❌ Lỗi khi tạo order:\n";
        echo $response;
    }
    
} catch (Exception $e) {
    echo "❌ Exception: " . $e->getMessage() . "\n";
}

$conn->close();
?> 