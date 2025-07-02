<?php
header('Content-Type: application/json');

require_once '../config/db_connect.php';

echo "=== Test Platform Fee Simple ===\n\n";

try {
    // Test với sản phẩm agency
    $order_data = [
        'user_id' => 4,
        'address_id' => 3,
        'payment_method' => 'COD',
        'items' => [
            [
                'product_id' => 15,
                'variant_id' => 16,
                'quantity' => 2
            ]
        ]
    ];
    
    echo "Order Data: " . json_encode($order_data) . "\n\n";
    
    // Gọi API
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
    echo "Response: $response\n\n";
    
    $response_data = json_decode($response, true);
    
    if ($response_data && $response_data['success']) {
        $order_id = $response_data['order_id'];
        echo "✅ Order created with ID: $order_id\n\n";
        
        // Kiểm tra database
        $query = "
            SELECT 
                o.id as order_id,
                o.total_amount,
                o.platform_fee,
                oi.quantity,
                oi.price,
                oi.platform_fee as item_platform_fee
            FROM orders o
            JOIN order_items oi ON o.id = oi.order_id
            WHERE o.id = ?
        ";
        
        $stmt = $conn->prepare($query);
        $stmt->bind_param("i", $order_id);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows > 0) {
            $row = $result->fetch_assoc();
            echo "=== Database Results ===\n";
            echo "Order ID: {$row['order_id']}\n";
            echo "Total Amount: {$row['total_amount']} VND\n";
            echo "Order Platform Fee: {$row['platform_fee']} VND\n";
            echo "Item Quantity: {$row['quantity']}\n";
            echo "Item Price: {$row['price']} VND\n";
            echo "Item Platform Fee: {$row['item_platform_fee']} VND\n\n";
            
            // Tính toán expected
            $expected_total = 960000; // 480,000 * 2
            $expected_platform_fee = 160000; // 80,000 * 2
            
            echo "=== Comparison ===\n";
            echo "Expected Total: $expected_total VND\n";
            echo "Actual Total: {$row['total_amount']} VND\n";
            echo "Total Match: " . ($expected_total == $row['total_amount'] ? "✅" : "❌") . "\n\n";
            
            echo "Expected Platform Fee: $expected_platform_fee VND\n";
            echo "Actual Platform Fee: {$row['platform_fee']} VND\n";
            echo "Platform Fee Match: " . ($expected_platform_fee == $row['platform_fee'] ? "✅" : "❌") . "\n\n";
            
            echo "Expected Item Platform Fee: $expected_platform_fee VND\n";
            echo "Actual Item Platform Fee: {$row['item_platform_fee']} VND\n";
            echo "Item Platform Fee Match: " . ($expected_platform_fee == $row['item_platform_fee'] ? "✅" : "❌") . "\n";
            
        } else {
            echo "❌ No data found for order ID: $order_id\n";
        }
        
    } else {
        echo "❌ Failed to create order\n";
        echo $response;
    }
    
} catch (Exception $e) {
    echo "❌ Exception: " . $e->getMessage() . "\n";
}

$conn->close();
?> 