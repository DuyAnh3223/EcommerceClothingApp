<?php
// Test script to check agency APIs
echo "<h2>Testing Agency APIs</h2>";

// Test 1: Check if server is running
echo "<h3>1. Server Status</h3>";
echo "✅ PHP Server is running<br>";
echo "Current time: " . date('Y-m-d H:i:s') . "<br><br>";

// Test 2: Check database connection
echo "<h3>2. Database Connection</h3>";
require_once 'config/db_connect.php';
if ($conn) {
    echo "✅ Database connected successfully<br>";
    
    // Check if agency products exist
    $sql = "SELECT COUNT(*) as count FROM products WHERE is_agency_product = 1";
    $result = $conn->query($sql);
    if ($result) {
        $count = $result->fetch_assoc()['count'];
        echo "Agency products in database: $count<br>";
    }
    
    // Check if attributes exist
    $sql = "SELECT COUNT(*) as count FROM attributes";
    $result = $conn->query($sql);
    if ($result) {
        $count = $result->fetch_assoc()['count'];
        echo "Attributes in database: $count<br>";
    }
} else {
    echo "❌ Database connection failed<br>";
}
echo "<br>";

// Test 3: Test get_products.php
echo "<h3>3. Testing get_products.php</h3>";
$url = "http://127.0.0.1/EcommerceClothingApp/API/agency/get_products.php";
echo "URL: $url<br>";

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HEADER, false);
curl_setopt($ch, CURLOPT_TIMEOUT, 10);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);
curl_close($ch);

if ($error) {
    echo "❌ cURL Error: $error<br>";
} else {
    echo "✅ HTTP Status: $httpCode<br>";
    if ($httpCode == 200) {
        echo "✅ API Response:<br>";
        echo "<pre>" . htmlspecialchars($response) . "</pre>";
    } else {
        echo "❌ API returned status $httpCode<br>";
    }
}
echo "<br>";

// Test 4: Test get_attributes.php
echo "<h3>4. Testing get_attributes.php</h3>";
$url = "http://127.0.0.1/EcommerceClothingApp/API/agency/get_attributes.php";
echo "URL: $url<br>";

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HEADER, false);
curl_setopt($ch, CURLOPT_TIMEOUT, 10);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);
curl_close($ch);

if ($error) {
    echo "❌ cURL Error: $error<br>";
} else {
    echo "✅ HTTP Status: $httpCode<br>";
    if ($httpCode == 200) {
        echo "✅ API Response:<br>";
        echo "<pre>" . htmlspecialchars($response) . "</pre>";
    } else {
        echo "❌ API returned status $httpCode<br>";
    }
}
echo "<br>";

// Test 5: Check file permissions
echo "<h3>5. File Permissions</h3>";
$files = [
    'agency/get_products.php',
    'agency/get_attributes.php',
    'config/db_connect.php',
    'utils/response.php'
];

foreach ($files as $file) {
    if (file_exists($file)) {
        echo "✅ $file exists<br>";
        if (is_readable($file)) {
            echo "✅ $file is readable<br>";
        } else {
            echo "❌ $file is not readable<br>";
        }
    } else {
        echo "❌ $file does not exist<br>";
    }
}

$conn->close();
?> 