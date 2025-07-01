<?php
// Debug script for add_attribute.php
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "=== Debug Add Attribute ===\n\n";

// Test database connection
echo "1. Testing database connection...\n";
include_once 'config/db_connect.php';
if ($conn->connect_error) {
    echo "✗ Database connection failed: " . $conn->connect_error . "\n";
    exit;
} else {
    echo "✓ Database connection successful\n";
}

// Test authentication
echo "\n2. Testing authentication...\n";
include_once 'utils/auth.php';
$user = authenticate();
if (!$user) {
    echo "✗ Authentication failed\n";
    echo "Session data: " . print_r($_SESSION ?? [], true) . "\n";
    echo "Headers: " . print_r(getallheaders() ?? [], true) . "\n";
    
    // Try to get a valid agency user directly from database
    echo "\nTrying to get agency user from database...\n";
    $result = $conn->query("SELECT id, username, role FROM users WHERE role = 'agency' LIMIT 1");
    if ($result && $result->num_rows > 0) {
        $user = $result->fetch_assoc();
        echo "✓ Found agency user: ID " . $user['id'] . ", Username: " . $user['username'] . "\n";
    } else {
        echo "✗ No agency user found in database\n";
        exit;
    }
} else {
    echo "✓ Authentication successful\n";
    echo "User ID: " . $user['id'] . "\n";
    echo "User Role: " . $user['role'] . "\n";
}

// Test table structure
echo "\n3. Testing attributes table structure...\n";
$result = $conn->query("DESCRIBE attributes");
if ($result) {
    echo "✓ Attributes table structure:\n";
    while ($row = $result->fetch_assoc()) {
        echo "  - " . $row['Field'] . " (" . $row['Type'] . ") " . ($row['Null'] == 'NO' ? 'NOT NULL' : 'NULL') . "\n";
    }
} else {
    echo "✗ Failed to describe attributes table: " . $conn->error . "\n";
}

// Test insert operation
echo "\n4. Testing insert operation...\n";
$test_name = "Test Attribute " . time();
$test_user_id = $user['id']; // Use the actual user ID from database

echo "Test data:\n";
echo "  - Name: $test_name\n";
echo "  - Created by: $test_user_id\n";

$stmt = $conn->prepare("INSERT INTO attributes (name, created_by) VALUES (?, ?)");
if (!$stmt) {
    echo "✗ Prepare statement failed: " . $conn->error . "\n";
} else {
    $stmt->bind_param("si", $test_name, $test_user_id);
    if ($stmt->execute()) {
        $attribute_id = $conn->insert_id;
        echo "✓ Insert successful, ID: $attribute_id\n";
        
        // Clean up test data
        $conn->query("DELETE FROM attributes WHERE id = $attribute_id");
        echo "✓ Test data cleaned up\n";
    } else {
        echo "✗ Execute failed: " . $stmt->error . "\n";
    }
    $stmt->close();
}

// Test JSON parsing
echo "\n5. Testing JSON parsing...\n";
$test_json = '{"name": "Test JSON Attribute"}';
$parsed = json_decode($test_json, true);
if ($parsed === null) {
    echo "✗ JSON parsing failed: " . json_last_error_msg() . "\n";
} else {
    echo "✓ JSON parsing successful\n";
    echo "  Parsed data: " . print_r($parsed, true) . "\n";
}

// Test response function
echo "\n6. Testing response function...\n";
include_once 'utils/response.php';
echo "✓ Response function loaded\n";

echo "\n=== Debug completed ===\n";
$conn->close();
?> 