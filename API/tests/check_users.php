<?php
header('Content-Type: application/json');

require_once '../config/db_connect.php';

echo "=== Checking Users ===\n\n";

try {
    // Check all users
    $users_query = "SELECT id, username, email, role FROM users ORDER BY id";
    $users_result = $conn->query($users_query);
    
    echo "Total users: " . $users_result->num_rows . "\n\n";
    
    while ($row = $users_result->fetch_assoc()) {
        echo "User ID: " . $row['id'] . "\n";
        echo "Username: " . $row['username'] . "\n";
        echo "Email: " . $row['email'] . "\n";
        echo "Role: " . $row['role'] . "\n";
        echo "---\n";
    }
    
    // Check if user ID 1 exists
    $check_user_1 = "SELECT id, username FROM users WHERE id = 1";
    $result = $conn->query($check_user_1);
    
    if ($result->num_rows > 0) {
        $user = $result->fetch_assoc();
        echo "\n✓ User ID 1 exists: " . $user['username'] . "\n";
    } else {
        echo "\n✗ User ID 1 does not exist!\n";
        
        // Get the first admin user
        $admin_query = "SELECT id, username FROM users WHERE role = 'admin' LIMIT 1";
        $admin_result = $conn->query($admin_query);
        
        if ($admin_result->num_rows > 0) {
            $admin = $admin_result->fetch_assoc();
            echo "First admin user: ID " . $admin['id'] . " - " . $admin['username'] . "\n";
        } else {
            echo "No admin users found!\n";
        }
    }
    
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}

$conn->close();
?> 