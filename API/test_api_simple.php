<?php
// Simple test for get_packages.php API
echo "<h1>Simple API Test</h1>";

// Test the API directly
$api_url = 'http://localhost/EcommerceClothingApp/API/admin/bacoin_packages/get_packages.php';

echo "<p>Testing API: <code>$api_url</code></p>";

// Use cURL to test the API
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $api_url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Accept: application/json'
]);

$response = curl_exec($ch);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "<h3>HTTP Status Code: $http_code</h3>";
echo "<h3>Response:</h3>";
echo "<pre style='background: #f5f5f5; padding: 10px; border-radius: 5px; max-height: 400px; overflow-y: auto;'>";
echo htmlspecialchars($response);
echo "</pre>";

// Parse JSON response
$data = json_decode($response, true);
if ($data) {
    echo "<h3>Parsed Data:</h3>";
    if (isset($data['status']) && $data['status'] == 200) {
        echo "<p style='color: green;'>✓ API Success!</p>";
        if (isset($data['data']) && is_array($data['data'])) {
            echo "<p>Found " . count($data['data']) . " packages:</p>";
            echo "<ul>";
            foreach ($data['data'] as $package) {
                echo "<li><strong>{$package['package_name']}</strong> - {$package['price_vnd']} VNĐ → {$package['bacoin_amount']} BACoin</li>";
            }
            echo "</ul>";
        }
    } else {
        echo "<p style='color: red;'>✗ API Error: " . ($data['message'] ?? 'Unknown error') . "</p>";
    }
} else {
    echo "<p style='color: red;'>✗ Invalid JSON response</p>";
}

echo "<h3>Manual Test Links:</h3>";
echo "<p><a href='admin/bacoin_packages/get_packages.php' target='_blank'>Direct API Link</a></p>";
echo "<p><a href='test_get_packages.html' target='_blank'>HTML Test Page</a></p>";
echo "<p><a href='test_bacoin_api.php' target='_blank'>Full Test Page</a></p>";
?> 