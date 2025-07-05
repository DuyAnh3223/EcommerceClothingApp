<?php
// Test script for Voucher API
header('Content-Type: text/html; charset=utf-8');

echo "<h1>Test Voucher API</h1>";

// Test database connection
require_once 'config/db_connect.php';
if ($conn) {
    echo "<p style='color: green;'>✓ Database connection successful</p>";
} else {
    echo "<p style='color: red;'>✗ Database connection failed</p>";
    exit;
}

// Test get vouchers
echo "<h2>Testing GET Vouchers API</h2>";
try {
    $stmt = $conn->prepare("SELECT * FROM vouchers ORDER BY created_at DESC");
    $stmt->execute();
    $result = $stmt->get_result();
    $vouchers = [];
    while ($row = $result->fetch_assoc()) {
        $vouchers[] = $row;
    }
    
    echo "<p style='color: green;'>✓ Found " . count($vouchers) . " vouchers</p>";
    
    if (count($vouchers) > 0) {
        echo "<h3>Vouchers in database:</h3>";
        echo "<table border='1' style='border-collapse: collapse; width: 100%;'>";
        echo "<tr><th>ID</th><th>Voucher Code</th><th>Discount Amount</th><th>Quantity</th><th>Start Date</th><th>End Date</th></tr>";
        
        foreach ($vouchers as $voucher) {
            echo "<tr>";
            echo "<td>{$voucher['id']}</td>";
            echo "<td>{$voucher['voucher_code']}</td>";
            echo "<td>" . number_format($voucher['discount_amount']) . " VNĐ</td>";
            echo "<td>{$voucher['quantity']}</td>";
            echo "<td>{$voucher['start_date']}</td>";
            echo "<td>{$voucher['end_date']}</td>";
            echo "</tr>";
        }
        echo "</table>";
    }
    
} catch (Exception $e) {
    echo "<p style='color: red;'>✗ Error: " . $e->getMessage() . "</p>";
}

// Test authentication
echo "<h2>Testing Authentication</h2>";
require_once 'utils/auth.php';
$user = authenticate();
if ($user) {
    echo "<p style='color: green;'>✓ Authentication successful - User ID: {$user['id']}, Role: {$user['role']}</p>";
} else {
    echo "<p style='color: red;'>✗ Authentication failed</p>";
}

// Test API endpoint directly
echo "<h2>Testing API Endpoint</h2>";
echo "<p>Testing: <code>admin/vouchers/get_vouchers.php</code></p>";

// Simulate the API call
$_SERVER['REQUEST_METHOD'] = 'GET';
$_SESSION['user_id'] = 6; // Admin user ID
$_SESSION['role'] = 'admin';

ob_start();
include 'admin/vouchers/get_vouchers.php';
$api_output = ob_get_clean();

echo "<h3>API Response:</h3>";
echo "<pre style='background: #f5f5f5; padding: 10px; border-radius: 5px;'>";
echo htmlspecialchars($api_output);
echo "</pre>";

// Test JSON parsing
$json_data = json_decode($api_output, true);
if ($json_data) {
    echo "<p style='color: green;'>✓ JSON response is valid</p>";
    if (isset($json_data['success']) && $json_data['success'] == 200) {
        echo "<p style='color: green;'>✓ API returned success status</p>";
        if (isset($json_data['data']) && is_array($json_data['data'])) {
            echo "<p style='color: green;'>✓ API returned " . count($json_data['data']) . " vouchers</p>";
        }
    } else {
        echo "<p style='color: red;'>✗ API returned error: " . ($json_data['message'] ?? 'Unknown error') . "</p>";
    }
} else {
    echo "<p style='color: red;'>✗ Invalid JSON response</p>";
}

echo "<h2>Manual API Test</h2>";
echo "<p>You can also test the API manually by visiting:</p>";
echo "<p><a href='admin/vouchers/get_vouchers.php' target='_blank'>http://localhost/EcommerceClothingApp/API/admin/vouchers/get_vouchers.php</a></p>";

echo "<h2>Voucher Validation Test</h2>";
echo "<p>Test voucher validation:</p>";
echo "<p><a href='vouchers/validate_voucher.php' target='_blank'>http://localhost/EcommerceClothingApp/API/vouchers/validate_voucher.php</a></p>";

echo "<h2>Flutter Web Test</h2>";
echo "<p>To test with Flutter web, run:</p>";
echo "<code>flutter run -d chrome --web-port=8080</code>";
echo "<p>Then open: <a href='http://localhost:8080' target='_blank'>http://localhost:8080</a></p>";
?> 