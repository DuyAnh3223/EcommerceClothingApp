<?php
// Test with real database data
require_once 'config/db_connect.php';

echo "=== TEST WITH REAL DATA ===\n\n";

// Get a valid user
$user_result = $conn->query("SELECT id, username FROM users LIMIT 1");
if (!$user_result || $user_result->num_rows == 0) {
    echo "ERROR: No users found in database!\n";
    exit;
}
$user = $user_result->fetch_assoc();
$user_id = $user['id'];
echo "Using User ID: {$user_id} (Username: {$user['username']})\n";

// Get a valid address for this user
$address_result = $conn->query("SELECT id, address_line FROM user_addresses WHERE user_id = {$user_id} LIMIT 1");
if (!$address_result || $address_result->num_rows == 0) {
    echo "ERROR: No addresses found for user {$user_id}!\n";
    exit;
}
$address = $address_result->fetch_assoc();
$address_id = $address['id'];
echo "Using Address ID: {$address_id} (Address: {$address['address_line']})\n";

// Get a valid product and variant
$product_result = $conn->query("
    SELECT p.id as product_id, p.name, pv.variant_id, pv.price, pv.stock 
    FROM products p 
    JOIN product_variant pv ON p.id = pv.product_id 
    WHERE p.status = 'active' AND pv.status = 'active' AND pv.stock > 0 
    LIMIT 1
");
if (!$product_result || $product_result->num_rows == 0) {
    echo "ERROR: No active products with variants found!\n";
    exit;
}
$product = $product_result->fetch_assoc();
$product_id = $product['product_id'];
$variant_id = $product['variant_id'];
echo "Using Product ID: {$product_id} (Name: {$product['name']}), Variant ID: {$variant_id}, Price: {$product['price']}, Stock: {$product['stock']}\n";

// Test data with real IDs
$test_data = [
    'user_id' => $user_id,
    'address_id' => $address_id,
    'payment_method' => 'BACoin',
    'cart_items' => [
        [
            'type' => 'product',
            'product_id' => $product_id,
            'variant_id' => $variant_id,
            'quantity' => 1
        ]
    ]
];

echo "\nTest Data: " . json_encode($test_data) . "\n\n";

// Test the API
$api_url = 'http://localhost/EcommerceClothingApp/API/orders/place_order_with_combinations.php';
echo "Testing API with real data...\n";

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $api_url);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($test_data));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json'
]);

$response = curl_exec($ch);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);
curl_close($ch);

echo "HTTP Code: $http_code\n";
if ($error) {
    echo "CURL Error: $error\n";
}
echo "Response: $response\n\n";

// Also test with COD payment method
echo "Testing with COD payment method...\n";
$test_data['payment_method'] = 'COD';

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $api_url);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($test_data));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json'
]);

$response = curl_exec($ch);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);
curl_close($ch);

echo "HTTP Code: $http_code\n";
if ($error) {
    echo "CURL Error: $error\n";
}
echo "Response: $response\n\n";

echo "=== TEST COMPLETE ===\n";
?> 