<?php
// Test đơn giản cho API voucher
header('Content-Type: application/json');

// Test data
$test_data = [
    'user_id' => 4,
    'cart_total' => 65000,
    'cart_quantity' => 1
];

// Gọi API
$url = 'http://localhost/EcommerceClothingApp/API/vouchers/get_available_vouchers.php';

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($test_data));
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json'
]);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

$response = curl_exec($ch);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "HTTP Code: " . $http_code . "\n";
echo "Response: " . $response . "\n";

// Test với dữ liệu khác
$test_data2 = [
    'user_id' => 4,
    'cart_total' => 210000,
    'cart_quantity' => 3
];

curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($test_data2));
$response2 = curl_exec($ch);
curl_close($ch);

echo "\nTest Case 2:\n";
echo "Response: " . $response2 . "\n";
?> 