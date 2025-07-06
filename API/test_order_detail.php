<?php
// Test script để kiểm tra API get_order_detail.php cho đơn hàng BACoin
require_once 'config/db_connect.php';

echo "=== Test Order Detail API ===\n\n";

// Lấy đơn hàng BACoin gần nhất
$query = "
    SELECT o.id, o.total_amount, o.total_amount_bacoin, p.payment_method, p.amount, p.amount_bacoin
    FROM orders o
    JOIN payments p ON o.id = p.order_id
    WHERE p.payment_method = 'BACoin' AND p.status = 'paid'
    ORDER BY o.id DESC
    LIMIT 1
";

$result = $conn->query($query);

if ($result->num_rows > 0) {
    $order = $result->fetch_assoc();
    $order_id = $order['id'];
    
    echo "Testing Order #{$order_id}\n";
    echo "Order total_amount: {$order['total_amount']} VNĐ\n";
    echo "Order total_amount_bacoin: {$order['total_amount_bacoin']} BACoin\n";
    echo "Payment amount: {$order['amount']} VNĐ\n";
    echo "Payment amount_bacoin: {$order['amount_bacoin']} BACoin\n";
    echo str_repeat("-", 50) . "\n";
    
    // Test API call
    $api_url = "http://127.0.0.1/EcommerceClothingApp/API/orders/get_order_detail.php?order_id={$order_id}";
    echo "Calling API: {$api_url}\n\n";
    
    $response = file_get_contents($api_url);
    $data = json_decode($response, true);
    
    if ($data['success']) {
        $order_detail = $data['data'];
        echo "API Response:\n";
        echo "Order ID: {$order_detail['id']}\n";
        echo "Total Amount: {$order_detail['total_amount']} VNĐ\n";
        echo "Total Amount BACoin: {$order_detail['total_amount_bacoin']} BACoin\n";
        echo "Status: {$order_detail['status']}\n";
        
        if (!empty($order_detail['payments'])) {
            $payment = $order_detail['payments'][0];
            echo "\nPayment Details:\n";
            echo "Method: {$payment['payment_method']}\n";
            echo "Amount: {$payment['amount']} VNĐ\n";
            echo "Amount BACoin: {$payment['amount_bacoin']} BACoin\n";
            echo "Status: {$payment['status']}\n";
        }
        
        if (!empty($order_detail['items'])) {
            echo "\nOrder Items:\n";
            foreach ($order_detail['items'] as $item) {
                echo "- {$item['product_name']}: {$item['price']} VNĐ (Qty: {$item['quantity']})\n";
            }
        }
    } else {
        echo "API Error: {$data['message']}\n";
    }
} else {
    echo "No BACoin orders found.\n";
}

echo "\n=== Test Complete ===\n";
?> 