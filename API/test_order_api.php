<?php
// Test file cho API place_order_with_combinations.php
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

echo "=== Test Order API ===\n";
echo "Test Data: " . json_encode($test_data) . "\n\n";

// Test POST request
echo "Test: POST request\n";
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
$error = curl_error($ch);
curl_close($ch);

echo "HTTP Code: $http_code\n";
if ($error) {
    echo "CURL Error: $error\n";
}
echo "Response: $response\n\n";

echo "=== Test Complete ===\n";
?> 