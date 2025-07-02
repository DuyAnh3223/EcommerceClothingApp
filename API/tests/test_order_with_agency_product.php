<?php
header('Content-Type: application/json');

require_once '../config/db_connect.php';

echo "=== Test tạo Order với sản phẩm Agency ===\n\n";

try {
    // 1. Tìm user để tạo order
    $user_query = "SELECT id, username FROM users WHERE role = 'user' LIMIT 1";
    $user_result = $conn->query($user_query);
    
    if ($user_result->num_rows === 0) {
        echo "Không tìm thấy user nào. Tạo user mới...\n";
        
        $stmt = $conn->prepare("
            INSERT INTO users (username, email, phone, password, role) 
            VALUES ('test_user', 'test_user@gmail.com', '0987654321', ?, 'user')
        ");
        $password = md5('123456');
        $stmt->bind_param("s", $password);
        $stmt->execute();
        $user_id = $conn->insert_id;
        echo "Đã tạo user với ID: $user_id\n";
    } else {
        $user = $user_result->fetch_assoc();
        $user_id = $user['id'];
        echo "Sử dụng user: {$user['username']} (ID: $user_id)\n";
    }
    
    // 2. Tìm address của user
    $address_query = "SELECT id FROM user_addresses WHERE user_id = ? LIMIT 1";
    $address_stmt = $conn->prepare($address_query);
    $address_stmt->bind_param("i", $user_id);
    $address_stmt->execute();
    $address_result = $address_stmt->get_result();
    
    if ($address_result->num_rows === 0) {
        echo "Không tìm thấy address. Tạo address mới...\n";
        
        $stmt = $conn->prepare("
            INSERT INTO user_addresses (user_id, address_line, city, province, postal_code, is_default) 
            VALUES (?, '123 Test Street', 'Ho Chi Minh', 'Ho Chi Minh', '70000', 1)
        ");
        $stmt->bind_param("i", $user_id);
        $stmt->execute();
        $address_id = $conn->insert_id;
        echo "Đã tạo address với ID: $address_id\n";
    } else {
        $address = $address_result->fetch_assoc();
        $address_id = $address['id'];
        echo "Sử dụng address với ID: $address_id\n";
    }
    
    // 3. Lấy thông tin sản phẩm agency để test
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
    
    echo "\n=== Thông tin sản phẩm sẽ order ===\n";
    echo "Product ID: $product_id\n";
    echo "Product Name: {$product['name']}\n";
    echo "Variant ID: $variant_id\n";
    echo "Base Price: $base_price VND\n";
    echo "Platform Fee Rate: $platform_fee_rate%\n";
    echo "Platform Fee: $platform_fee VND\n";
    echo "Final Price: $final_price VND\n";
    
    // 4. Tạo order data
    $order_data = [
        'user_id' => $user_id,
        'address_id' => $address_id,
        'items' => [
            [
                'product_id' => $product_id,
                'variant_id' => $variant_id,
                'quantity' => 2
            ]
        ],
        'status' => 'pending'
    ];
    
    echo "\n=== Order Data ===\n";
    echo json_encode($order_data, JSON_PRETTY_PRINT) . "\n";
    
    // 5. Tính toán expected values
    $expected_total = $final_price * 2; // 2 items
    $expected_platform_fee = $platform_fee * 2;
    
    echo "\n=== Expected Results ===\n";
    echo "Expected Total Amount: $expected_total VND\n";
    echo "Expected Platform Fee: $expected_platform_fee VND\n";
    
    // 6. Gọi API add_order
    echo "\n=== Gọi API add_order ===\n";
    
    $url = 'http://localhost/EcommerceClothingApp/API/orders/add_order.php';
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
    
    // 7. Parse response
    $response_data = json_decode($response, true);
    
    if ($response_data && $response_data['success']) {
        echo "\n✅ Order được tạo thành công!\n";
        echo "Order ID: {$response_data['order_id']}\n";
        echo "Actual Total Amount: {$response_data['total_amount']} VND\n";
        echo "Actual Platform Fee: {$response_data['platform_fee']} VND\n";
        
        // 8. Kiểm tra order trong database
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
        
        while ($order_row = $order_check_result->fetch_assoc()) {
            echo "Order ID: {$order_row['id']}\n";
            echo "Total Amount: {$order_row['total_amount']} VND\n";
            echo "Platform Fee: {$order_row['platform_fee']} VND\n";
            echo "Item Price: {$order_row['price']} VND\n";
            echo "Item Platform Fee: {$order_row['platform_fee']} VND\n";
        }
        
        // 9. So sánh expected vs actual
        echo "\n=== So sánh Expected vs Actual ===\n";
        $actual_total = $response_data['total_amount'];
        $actual_platform_fee = $response_data['platform_fee'];
        
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