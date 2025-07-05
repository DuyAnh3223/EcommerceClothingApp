<?php
// Test file để kiểm tra API validate voucher
header('Content-Type: application/json');

// Test data với voucher mới TEST2025
$testData = [
    'voucher_code' => 'TEST2025',
    'product_ids' => [4, 6, 20] // Product IDs từ database
];

// Gọi API validate voucher
$url = 'http://localhost/EcommerceClothingApp/API/vouchers/validate_voucher.php';

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($testData));
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Content-Length: ' . strlen(json_encode($testData))
]);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 30);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);
curl_close($ch);

echo "=== TEST VOUCHER VALIDATE API ===\n";
echo "URL: $url\n";
echo "Test Data: " . json_encode($testData, JSON_PRETTY_PRINT) . "\n";
echo "HTTP Code: $httpCode\n";

if ($error) {
    echo "CURL Error: $error\n";
} else {
    echo "Response: $response\n";
    
    // Parse response
    $data = json_decode($response, true);
    if ($data) {
        echo "Parsed Response:\n";
        echo json_encode($data, JSON_PRETTY_PRINT) . "\n";
    }
}
?> 