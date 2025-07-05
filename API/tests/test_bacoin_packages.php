<?php
// Test file for BACoin Packages API
require_once '../config/db_connect.php';

echo "<h1>Test BACoin Packages API</h1>";

// Test 1: Get all packages
echo "<h2>Test 1: Get all packages</h2>";
$url = "http://localhost/EcommerceClothingApp/API/admin/bacoin_packages/get_packages.php";
$response = file_get_contents($url);
echo "<pre>Response: " . $response . "</pre>";

// Test 2: Add new package
echo "<h2>Test 2: Add new package</h2>";
$data = [
    'package_name' => 'Gói Test 200K',
    'price_vnd' => 200000,
    'bacoin_amount' => 250000,
    'description' => 'Gói test mới'
];

$options = [
    'http' => [
        'header' => "Content-type: application/json\r\n",
        'method' => 'POST',
        'content' => json_encode($data)
    ]
];

$context = stream_context_create($options);
$url = "http://localhost/EcommerceClothingApp/API/admin/bacoin_packages/add_package.php";
$response = file_get_contents($url, false, $context);
echo "<pre>Response: " . $response . "</pre>";

// Test 3: Update package
echo "<h2>Test 3: Update package</h2>";
$data = [
    'id' => 1,
    'package_name' => 'Gói 50K Updated',
    'price_vnd' => 50000,
    'bacoin_amount' => 60000,
    'description' => 'Gói 50K đã được cập nhật'
];

$options = [
    'http' => [
        'header' => "Content-type: application/json\r\n",
        'method' => 'PUT',
        'content' => json_encode($data)
    ]
];

$context = stream_context_create($options);
$url = "http://localhost/EcommerceClothingApp/API/admin/bacoin_packages/update_package.php";
$response = file_get_contents($url, false, $context);
echo "<pre>Response: " . $response . "</pre>";

// Test 4: Delete package (uncomment to test)
/*
echo "<h2>Test 4: Delete package</h2>";
$data = ['id' => 6]; // Replace with actual ID

$options = [
    'http' => [
        'header' => "Content-type: application/json\r\n",
        'method' => 'DELETE',
        'content' => json_encode($data)
    ]
];

$context = stream_context_create($options);
$url = "http://localhost/EcommerceClothingApp/API/admin/bacoin_packages/delete_package.php";
$response = file_get_contents($url, false, $context);
echo "<pre>Response: " . $response . "</pre>";
*/

echo "<h2>Database Check</h2>";
try {
    $stmt = $conn->prepare("SELECT * FROM bacoin_packages ORDER BY price_vnd ASC");
    $stmt->execute();
    $packages = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "<table border='1'>";
    echo "<tr><th>ID</th><th>Package Name</th><th>Price VND</th><th>BACoin Amount</th><th>Description</th></tr>";
    foreach ($packages as $package) {
        echo "<tr>";
        echo "<td>" . $package['id'] . "</td>";
        echo "<td>" . $package['package_name'] . "</td>";
        echo "<td>" . $package['price_vnd'] . "</td>";
        echo "<td>" . $package['bacoin_amount'] . "</td>";
        echo "<td>" . ($package['description'] ?? '') . "</td>";
        echo "</tr>";
    }
    echo "</table>";
} catch (PDOException $e) {
    echo "Database error: " . $e->getMessage();
}
?> 