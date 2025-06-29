<?php
// Test file để kiểm tra place_order_multi.php với VNPAY
$url = 'http://localhost/EcommerceClothingApp/API/orders/place_order_multi.php';
$data = [
    'user_id' => 4,
    'address_id' => 3,
    'payment_method' => 'VNPAY',
    'items' => [
        [
            'product_id' => 3,
            'variant_id' => 4,
            'quantity' => 1
        ]
    ]
];

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Accept: application/json'
]);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 30);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);
curl_close($ch);

echo "HTTP Code: $httpCode\n";
echo "cURL Error: $error\n";
echo "Response:\n";
echo $response . "\n";
?> 