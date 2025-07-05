<?php
// Test platform fee logic for different payment methods
require_once 'config/db_connect.php';

echo "=== TEST PLATFORM FEE LOGIC ===\n\n";

// Test data
$user_id = 4; // user
$address_id = 3; // user's address

// Test cart items (agency product)
$cart_items = [
    [
        'type' => 'product',
        'product_id' => 31, // Quần lửng (agency product)
        'variant_id' => 27,
        'quantity' => 1
    ]
];

echo "Testing platform fee logic for different payment methods...\n";
echo "User ID: $user_id\n";
echo "Address ID: $address_id\n";
echo "Cart Items: " . json_encode($cart_items) . "\n\n";

// Test 1: BACoin payment
echo "=== TEST 1: BACOIN PAYMENT ===\n";
$payment_method = 'BACoin';

$api_url = 'http://localhost/EcommerceClothingApp/API/orders/place_order_with_combinations.php';

$post_data = [
    'user_id' => $user_id,
    'address_id' => $address_id,
    'payment_method' => $payment_method,
    'cart_items' => $cart_items
];

echo "Calling API for BACoin payment...\n";

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
curl_close($ch);

echo "HTTP Code: $http_code\n";
echo "Response: $response\n\n";

if ($http_code == 200) {
    $result = json_decode($response, true);
    if ($result['success']) {
        $order_id = $result['order_id'];
        echo "✅ BACoin order created successfully. Order ID: $order_id\n";
        
        // Check order amounts
        $order_sql = "SELECT total_amount, total_amount_bacoin, platform_fee, status FROM orders WHERE id = ?";
        $order_stmt = $conn->prepare($order_sql);
        $order_stmt->bind_param("i", $order_id);
        $order_stmt->execute();
        $order_result = $order_stmt->get_result();
        $order_data = $order_result->fetch_assoc();
        $order_stmt->close();
        
        echo "Order amounts:\n";
        echo "- total_amount: " . ($order_data['total_amount'] ?? 'NULL') . "\n";
        echo "- total_amount_bacoin: " . ($order_data['total_amount_bacoin'] ?? 'NULL') . "\n";
        echo "- platform_fee: " . ($order_data['platform_fee'] ?? 'NULL') . "\n";
        echo "- status: " . ($order_data['status'] ?? 'NULL') . "\n";
        
        // Check if BACoin logic is correct
        if ($order_data['total_amount'] == 0 && $order_data['platform_fee'] == 0) {
            echo "✅ CORRECT! BACoin payment: total_amount=0, platform_fee=0\n";
        } else {
            echo "❌ INCORRECT! BACoin payment amounts wrong\n";
        }
    }
}

// Test 2: COD payment
echo "\n=== TEST 2: COD PAYMENT ===\n";
$payment_method = 'COD';

$post_data['payment_method'] = $payment_method;

echo "Calling API for COD payment...\n";

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
curl_close($ch);

echo "HTTP Code: $http_code\n";
echo "Response: $response\n\n";

if ($http_code == 200) {
    $result = json_decode($response, true);
    if ($result['success']) {
        $order_id = $result['order_id'];
        echo "✅ COD order created successfully. Order ID: $order_id\n";
        
        // Check order amounts
        $order_sql = "SELECT total_amount, total_amount_bacoin, platform_fee, status FROM orders WHERE id = ?";
        $order_stmt = $conn->prepare($order_sql);
        $order_stmt->bind_param("i", $order_id);
        $order_stmt->execute();
        $order_result = $order_stmt->get_result();
        $order_data = $order_result->fetch_assoc();
        $order_stmt->close();
        
        echo "Order amounts:\n";
        echo "- total_amount: " . ($order_data['total_amount'] ?? 'NULL') . "\n";
        echo "- total_amount_bacoin: " . ($order_data['total_amount_bacoin'] ?? 'NULL') . "\n";
        echo "- platform_fee: " . ($order_data['platform_fee'] ?? 'NULL') . "\n";
        echo "- status: " . ($order_data['status'] ?? 'NULL') . "\n";
        
        // Check if COD logic is correct
        $expected_total = 60000; // 50,000 + 10,000 platform fee
        $expected_platform_fee = 10000;
        
        if ($order_data['total_amount'] == $expected_total && $order_data['platform_fee'] == $expected_platform_fee) {
            echo "✅ CORRECT! COD payment: total_amount=$expected_total, platform_fee=$expected_platform_fee\n";
        } else {
            echo "❌ INCORRECT! COD payment amounts wrong\n";
        }
    }
}

echo "\n=== TEST COMPLETE ===\n";
?> 