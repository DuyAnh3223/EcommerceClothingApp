<?php
include_once 'config/db_connect.php';

echo "=== Checking Agency Users ===\n";

// Check for agency users
$agency_sql = "SELECT id, username, email, role FROM users WHERE role = 'agency'";
$agency_result = $conn->query($agency_sql);

if ($agency_result && $agency_result->num_rows > 0) {
    echo "✓ Found " . $agency_result->num_rows . " agency user(s):\n";
    while ($user = $agency_result->fetch_assoc()) {
        echo "- ID: {$user['id']}, Username: {$user['username']}, Email: {$user['email']}, Role: {$user['role']}\n";
    }
} else {
    echo "✗ No agency users found\n";
}

// Check for admin users
$admin_sql = "SELECT id, username, email, role FROM users WHERE role = 'admin'";
$admin_result = $conn->query($admin_sql);

if ($admin_result && $admin_result->num_rows > 0) {
    echo "\n✓ Found " . $admin_result->num_rows . " admin user(s):\n";
    while ($user = $admin_result->fetch_assoc()) {
        echo "- ID: {$user['id']}, Username: {$user['username']}, Email: {$user['email']}, Role: {$user['role']}\n";
    }
} else {
    echo "\n✗ No admin users found\n";
}

// Test authentication
echo "\n=== Testing Authentication ===\n";
include_once 'utils/auth.php';

$user = authenticate();
if ($user) {
    echo "✓ Authentication successful:\n";
    echo "- User ID: {$user['id']}\n";
    echo "- Role: {$user['role']}\n";
} else {
    echo "✗ Authentication failed\n";
}

$conn->close();
?> 