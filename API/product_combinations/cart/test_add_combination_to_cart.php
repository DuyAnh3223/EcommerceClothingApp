<?php
// File test để kiểm tra API add_combination_to_cart.php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

// Dữ liệu test
$test_data = [
    'user_id' => 1, // Thay bằng user_id thực tế
    'combination_id' => 1, // Thay bằng combination_id thực tế
    'quantity' => 2,
    'items' => [
        [
            'product_id' => 3,
            'variant_id' => 4,
            'quantity' => 1
        ],
        [
            'product_id' => 4,
            'variant_id' => 6,
            'quantity' => 1
        ]
    ]
];

// Gọi API
$url = 'http://127.0.0.1/EcommerceClothingApp/API/product_combinations/cart/add_combination_to_cart.php';
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

echo "HTTP Code: $http_code\n";
echo "Response: $response\n";
?> 