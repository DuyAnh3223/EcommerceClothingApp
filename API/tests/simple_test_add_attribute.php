<?php
// Simple test for add_attribute API
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "=== Simple Test Add Attribute ===\n\n";

// Include required files
include_once 'config/db_connect.php';
include_once 'utils/response.php';
include_once 'utils/auth.php';

// For testing, directly get agency user from database
echo "1. Getting agency user from database...\n";
$result = $conn->query("SELECT id, username, role FROM users WHERE role = 'agency' LIMIT 1");
if ($result && $result->num_rows > 0) {
    $user = $result->fetch_assoc();
    echo "✓ Found agency user\n";
    echo "   User ID: " . $user['id'] . "\n";
    echo "   Username: " . $user['username'] . "\n";
    echo "   Role: " . $user['role'] . "\n\n";
} else {
    echo "✗ No agency user found\n\n";
    exit;
}

// Test adding attribute
echo "2. Testing add attribute...\n";
$test_name = "Test Attribute " . time();

$stmt = $conn->prepare("INSERT INTO attributes (name, created_by) VALUES (?, ?)");
if ($stmt) {
    $stmt->bind_param("si", $test_name, $user['id']);
    if ($stmt->execute()) {
        $attribute_id = $conn->insert_id;
        echo "✓ Attribute added successfully\n";
        echo "   ID: $attribute_id\n";
        echo "   Name: $test_name\n";
        echo "   Created by: " . $user['id'] . "\n";
        
        // Clean up
        $conn->query("DELETE FROM attributes WHERE id = $attribute_id");
        echo "✓ Test data cleaned up\n";
    } else {
        echo "✗ Failed to add attribute: " . $stmt->error . "\n";
    }
    $stmt->close();
} else {
    echo "✗ Prepare statement failed: " . $conn->error . "\n";
}

echo "\n=== Test completed ===\n";
$conn->close();
?> 