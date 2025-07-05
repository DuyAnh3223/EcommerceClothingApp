<?php
// Test BACoin payment amounts
require_once 'config/db_connect.php';

echo "=== TEST BACOIN AMOUNTS ===\n\n";

// Test data
$user_id = 4; // user
$address_id = 3; // user's address
$payment_method = 'BACoin';

// Test cart items
$cart_items = [
    [
        'type' => 'product',
        'product_id' => 31, // Quần lửng (agency product)
        'variant_id' => 27,
        'quantity' => 1
    ]
];

echo "Testing BACoin payment amounts...\n";
echo "User ID: $user_id\n";
echo "Address ID: $address_id\n";
echo "Payment Method: $payment_method\n\n";

// Check current order count
$order_count_sql = "SELECT COUNT(*) as count FROM orders";
$order_count_result = $conn->query($order_count_sql);
$current_order_count = $order_count_result->fetch_assoc()['count'];
echo "Current order count: $current_order_count\n\n";

// Test the API call
$api_url = 'http://localhost/EcommerceClothingApp/API/orders/place_order_with_combinations.php';

$post_data = [
    'user_id' => $user_id,
    'address_id' => $address_id,
    'payment_method' => $payment_method,
    'cart_items' => $cart_items
];

echo "Calling API...\n";

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $api_url);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($post_data));
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Accept: application/json'
]);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 30);

$response = curl_exec($ch);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$curl_error = curl_error($ch);
curl_close($ch);

echo "HTTP Code: $http_code\n";
if ($curl_error) {
    echo "CURL Error: $curl_error\n";
}
echo "Response: $response\n\n";

if ($http_code == 200) {
    $result = json_decode($response, true);
    if ($result['success']) {
        echo "SUCCESS! Order created successfully.\n";
        $order_id = $result['order_id'];
        echo "Order ID: $order_id\n";
        
        // Check the order amounts in database
        $order_sql = "SELECT total_amount, total_amount_bacoin, platform_fee, status FROM orders WHERE id = ?";
        $order_stmt = $conn->prepare($order_sql);
        $order_stmt->bind_param("i", $order_id);
        $order_stmt->execute();
        $order_result = $order_stmt->get_result();
        $order_data = $order_result->fetch_assoc();
        $order_stmt->close();
        
        echo "\n=== ORDER AMOUNTS CHECK ===\n";
        echo "Order ID: $order_id\n";
        echo "total_amount: " . ($order_data['total_amount'] ?? 'NULL') . "\n";
        echo "total_amount_bacoin: " . ($order_data['total_amount_bacoin'] ?? 'NULL') . "\n";
        echo "platform_fee: " . ($order_data['platform_fee'] ?? 'NULL') . "\n";
        echo "status: " . ($order_data['status'] ?? 'NULL') . "\n";
        
        // Check if amounts are correct
        $expected_bacoin = 60000; // 50,000 + 10,000 platform fee
        
        if ($order_data['total_amount'] == 0 && $order_data['total_amount_bacoin'] == $expected_bacoin) {
            echo "\n✅ CORRECT! BACoin payment amounts are set correctly:\n";
            echo "- total_amount = 0 (for BACoin payments)\n";
            echo "- total_amount_bacoin = $expected_bacoin\n";
        } else {
            echo "\n❌ INCORRECT! BACoin payment amounts are wrong:\n";
            echo "- Expected total_amount = 0, got: " . ($order_data['total_amount'] ?? 'NULL') . "\n";
            echo "- Expected total_amount_bacoin = $expected_bacoin, got: " . ($order_data['total_amount_bacoin'] ?? 'NULL') . "\n";
        }
        
        // Check payment record
        $payment_sql = "SELECT payment_method, amount, amount_bacoin, status, transaction_code FROM payments WHERE order_id = ?";
        $payment_stmt = $conn->prepare($payment_sql);
        $payment_stmt->bind_param("i", $order_id);
        $payment_stmt->execute();
        $payment_result = $payment_stmt->get_result();
        $payment_data = $payment_result->fetch_assoc();
        $payment_stmt->close();
        
        echo "\n=== PAYMENT RECORD CHECK ===\n";
        echo "payment_method: " . ($payment_data['payment_method'] ?? 'NULL') . "\n";
        echo "amount: " . ($payment_data['amount'] ?? 'NULL') . "\n";
        echo "amount_bacoin: " . ($payment_data['amount_bacoin'] ?? 'NULL') . "\n";
        echo "status: " . ($payment_data['status'] ?? 'NULL') . "\n";
        echo "transaction_code: " . ($payment_data['transaction_code'] ?? 'NULL') . "\n";
        
    } else {
        echo "ERROR: " . ($result['message'] ?? 'Unknown error') . "\n";
    }
} else {
    echo "HTTP Error: $http_code\n";
}

echo "\n=== TEST COMPLETE ===\n";
?> 