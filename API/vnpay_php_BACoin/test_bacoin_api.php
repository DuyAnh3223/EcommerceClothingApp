<?php
// Test file cho API bacoin_payment.php
header('Content-Type: application/json');

// Test data
$test_data = [
    'user_id' => 1,
    'order_id' => 1
];

echo "=== Test BACoin Payment API ===\n";
echo "Test Data: " . json_encode($test_data) . "\n\n";

// Test 1: POST request
echo "Test 1: POST request\n";
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, 'http://localhost/EcommerceClothingApp/API/vnpay_php_BACoin/bacoin_payment.php');
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($test_data));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/x-www-form-urlencoded'
]);

$response = curl_exec($ch);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "HTTP Code: $http_code\n";
echo "Response: $response\n\n";

// Test 2: GET request
echo "Test 2: GET request\n";
$ch = curl_init();
$url = 'http://localhost/EcommerceClothingApp/API/vnpay_php_BACoin/bacoin_payment.php?' . http_build_query($test_data);
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

$response = curl_exec($ch);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "HTTP Code: $http_code\n";
echo "Response: $response\n\n";

// Test 3: JSON request
echo "Test 3: JSON request\n";
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, 'http://localhost/EcommerceClothingApp/API/vnpay_php_BACoin/bacoin_payment.php');
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

echo "=== Test Complete ===\n";
?> 