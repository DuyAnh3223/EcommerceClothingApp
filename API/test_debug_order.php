<?php
// Comprehensive test script for debugging place_order_with_combinations.php
header('Content-Type: application/json');

echo "=== DEBUG ORDER API ===\n\n";

// Test 1: Check if the API file exists and is accessible
$api_url = 'http://localhost/EcommerceClothingApp/API/orders/place_order_with_combinations.php';
echo "1. Testing API accessibility...\n";
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $api_url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HEADER, true);
curl_setopt($ch, CURLOPT_NOBODY, true);
$response = curl_exec($ch);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "HTTP Code: $http_code\n";
if ($http_code == 404) {
    echo "ERROR: API file not found!\n";
    exit;
}
echo "✓ API file accessible\n\n";

// Test 2: Test with minimal valid data
echo "2. Testing with minimal valid data...\n";
$test_data = [
    'user_id' => 1,
    'address_id' => 1,
    'payment_method' => 'BACoin',
    'cart_items' => [
        [
            'type' => 'product',
            'product_id' => 1,
            'variant_id' => 1,
            'quantity' => 1
        ]
    ]
];

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

// Test 3: Test with POST form data
echo "3. Testing with POST form data...\n";
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $api_url);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($test_data));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/x-www-form-urlencoded'
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

// Test 4: Test with combination data
echo "4. Testing with combination data...\n";
$test_data_combo = [
    'user_id' => 1,
    'address_id' => 1,
    'payment_method' => 'BACoin',
    'cart_items' => [
        [
            'type' => 'combination',
            'combination_id' => 1,
            'quantity' => 1,
            'combination_price' => 100000
        ]
    ]
];

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $api_url);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($test_data_combo));
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

// Test 5: Test with empty data
echo "5. Testing with empty data...\n";
$test_data_empty = [
    'user_id' => 0,
    'address_id' => 0,
    'payment_method' => 'BACoin',
    'cart_items' => []
];

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $api_url);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($test_data_empty));
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

echo "=== DEBUG COMPLETE ===\n";
?> 