<?php
// Simple test for BACoin Packages API
echo "<h1>Test BACoin Packages API</h1>";

// Test 1: Get all packages
echo "<h2>Test 1: Get all packages</h2>";
$url = "http://localhost:8000/admin/bacoin_packages/get_packages.php";

$context = stream_context_create([
    'http' => [
        'method' => 'GET',
        'header' => 'Content-Type: application/json'
    ]
]);

$response = file_get_contents($url, false, $context);
echo "<pre>Response: " . $response . "</pre>";

// Test 2: Add new package
echo "<h2>Test 2: Add new package</h2>";
$data = [
    'package_name' => 'Gói Test 200K',
    'price_vnd' => 200000,
    'bacoin_amount' => 250000,
    'description' => 'Gói test mới'
];

$context = stream_context_create([
    'http' => [
        'method' => 'POST',
        'header' => 'Content-Type: application/json',
        'content' => json_encode($data)
    ]
]);

$url = "http://localhost:8000/admin/bacoin_packages/add_package.php";
$response = file_get_contents($url, false, $context);
echo "<pre>Response: " . $response . "</pre>";

echo "<h2>Database Check</h2>";
try {
    require_once 'config/db_connect.php';
    $stmt = $conn->prepare("SELECT * FROM bacoin_packages ORDER BY price_vnd ASC");
    $stmt->execute();
    $result = $stmt->get_result();
    
    echo "<table border='1'>";
    echo "<tr><th>ID</th><th>Package Name</th><th>Price VND</th><th>BACoin Amount</th><th>Description</th></tr>";
    while ($package = $result->fetch_assoc()) {
        echo "<tr>";
        echo "<td>" . $package['id'] . "</td>";
        echo "<td>" . $package['package_name'] . "</td>";
        echo "<td>" . $package['price_vnd'] . "</td>";
        echo "<td>" . $package['bacoin_amount'] . "</td>";
        echo "<td>" . ($package['description'] ?? '') . "</td>";
        echo "</tr>";
    }
    echo "</table>";
} catch (Exception $e) {
    echo "Database error: " . $e->getMessage();
}
?> 