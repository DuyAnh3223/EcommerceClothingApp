<?php
// Test file cho API place_order_with_combinations.php với các format khác nhau
header('Content-Type: application/json');

// Test data
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

echo "=== Test Order API with Different Formats ===\n\n";

// Test 1: JSON format
echo "Test 1: JSON format\n";
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, 'http://localhost/EcommerceClothingApp/API/orders/place_order_with_combinations.php');
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($test_data));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json'
]);

$response = curl_exec($ch);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "HTTP Code: $http_code\n";
echo "Response: $response\n\n";

// Test 2: Form data format
echo "Test 2: Form data format\n";
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, 'http://localhost/EcommerceClothingApp/API/orders/place_order_with_combinations.php');
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query([
    'user_id' => 1,
    'address_id' => 1,
    'payment_method' => 'BACoin',
    'cart_items' => json_encode($test_data['cart_items'])
]));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/x-www-form-urlencoded'
]);

$response = curl_exec($ch);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "HTTP Code: $http_code\n";
echo "Response: $response\n\n";

// Test 3: Empty request
echo "Test 3: Empty request\n";
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, 'http://localhost/EcommerceClothingApp/API/orders/place_order_with_combinations.php');
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, '');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json'
]);

$response = curl_exec($ch);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "HTTP Code: $http_code\n";
echo "Response: $response\n\n";

// Test 4: Invalid JSON
echo "Test 4: Invalid JSON\n";
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, 'http://localhost/EcommerceClothingApp/API/orders/place_order_with_combinations.php');
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, '{"invalid": json}');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json'
]);

$response = curl_exec($ch);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "HTTP Code: $http_code\n";
echo "Response: $response\n\n";

echo "=== Test Complete ===\n";
?> 