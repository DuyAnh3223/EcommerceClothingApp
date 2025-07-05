<?php
// Test BACoin payment functionality
require_once 'config/db_connect.php';

echo "=== TEST BACOIN PAYMENT ===\n\n";

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

echo "Testing with:\n";
echo "User ID: $user_id\n";
echo "Address ID: $address_id\n";
echo "Payment Method: $payment_method\n";
echo "Cart Items: " . json_encode($cart_items) . "\n\n";

// Check user balance
$balance_sql = "SELECT balance FROM users WHERE id = ?";
$balance_stmt = $conn->prepare($balance_sql);
$balance_stmt->bind_param("i", $user_id);
$balance_stmt->execute();
$balance_result = $balance_stmt->get_result();
$user_balance = $balance_result->fetch_assoc();
$balance_stmt->close();

echo "User Balance: " . ($user_balance['balance'] ?? 0) . "\n\n";

// Check product info
$product_sql = "SELECT p.name, p.is_agency_product, p.created_by, p.platform_fee_rate, pv.price, pv.stock 
                FROM products p 
                JOIN product_variant pv ON p.id = pv.product_id 
                WHERE p.id = ? AND pv.variant_id = ?";
$product_stmt = $conn->prepare($product_sql);
$product_stmt->bind_param("ii", $cart_items[0]['product_id'], $cart_items[0]['variant_id']);
$product_stmt->execute();
$product_result = $product_stmt->get_result();
$product_info = $product_result->fetch_assoc();
$product_stmt->close();

echo "Product Info:\n";
echo "Name: " . $product_info['name'] . "\n";
echo "Is Agency Product: " . ($product_info['is_agency_product'] ? 'Yes' : 'No') . "\n";
echo "Created By: " . $product_info['created_by'] . "\n";
echo "Platform Fee Rate: " . $product_info['platform_fee_rate'] . "%\n";
echo "Price: " . $product_info['price'] . "\n";
echo "Stock: " . $product_info['stock'] . "\n\n";

// Calculate expected total
$base_price = $product_info['price'];
$platform_fee_rate = $product_info['platform_fee_rate'];
$is_agency_product = $product_info['is_agency_product'];

$item_total = $base_price;
$platform_fee = 0;

if ($is_agency_product) {
    $platform_fee = $item_total * ($platform_fee_rate / 100);
}

$total_amount = $item_total + $platform_fee;

echo "Expected Total: $total_amount\n";
echo "Base Price: $base_price\n";
echo "Platform Fee: $platform_fee\n\n";

// Check if user has enough balance
if (($user_balance['balance'] ?? 0) < $total_amount) {
    echo "ERROR: Insufficient balance!\n";
    echo "Required: $total_amount\n";
    echo "Available: " . ($user_balance['balance'] ?? 0) . "\n";
    exit;
}

echo "Balance check passed!\n\n";

// Test the API call
$api_url = 'http://localhost/EcommerceClothingApp/API/orders/place_order_with_combinations.php';

$post_data = [
    'user_id' => $user_id,
    'address_id' => $address_id,
    'payment_method' => $payment_method,
    'cart_items' => $cart_items
];

echo "Calling API...\n";
echo "URL: $api_url\n";
echo "Data: " . json_encode($post_data) . "\n\n";

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
        echo "Order ID: " . ($result['order_id'] ?? 'N/A') . "\n";
        echo "Message: " . ($result['message'] ?? 'N/A') . "\n";
        
        // Check new balance
        $new_balance_stmt = $conn->prepare($balance_sql);
        $new_balance_stmt->bind_param("i", $user_id);
        $new_balance_stmt->execute();
        $new_balance_result = $new_balance_stmt->get_result();
        $new_user_balance = $new_balance_result->fetch_assoc();
        $new_balance_stmt->close();
        
        echo "New Balance: " . ($new_user_balance['balance'] ?? 0) . "\n";
        
        // Check agency balance
        $agency_id = $product_info['created_by'];
        $agency_balance_stmt = $conn->prepare("SELECT balance FROM users WHERE id = ?");
        $agency_balance_stmt->bind_param("i", $agency_id);
        $agency_balance_stmt->execute();
        $agency_balance_result = $agency_balance_stmt->get_result();
        $agency_balance = $agency_balance_result->fetch_assoc();
        $agency_balance_stmt->close();
        
        echo "Agency Balance: " . ($agency_balance['balance'] ?? 0) . "\n";
        
    } else {
        echo "ERROR: " . ($result['message'] ?? 'Unknown error') . "\n";
    }
} else {
    echo "HTTP Error: $http_code\n";
}

echo "\n=== TEST COMPLETE ===\n";
?> 