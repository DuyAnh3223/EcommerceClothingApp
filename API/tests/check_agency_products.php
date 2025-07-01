<?php
header('Content-Type: application/json');

require_once '../config/db_connect.php';

echo "=== Checking Agency Products in Database ===\n\n";

try {
    // Check all agency products
    $query = "
        SELECT 
            p.*,
            u.username,
            u.role
        FROM products p
        JOIN users u ON p.created_by = u.id
        WHERE p.is_agency_product = 1
        ORDER BY p.created_at DESC
    ";
    
    $result = $conn->query($query);
    
    echo "Total agency products found: " . $result->num_rows . "\n\n";
    
    if ($result->num_rows > 0) {
        while ($row = $result->fetch_assoc()) {
            echo "Product ID: " . $row['id'] . "\n";
            echo "Product Name: " . $row['name'] . "\n";
            echo "Status: " . $row['status'] . "\n";
            echo "Created By: " . $row['username'] . " (Role: " . $row['role'] . ")\n";
            echo "Created At: " . $row['created_at'] . "\n";
            echo "---\n";
        }
    }
    
    // Check all users with agency role
    echo "\n=== Agency Users ===\n";
    $users_query = "SELECT id, username, role FROM users WHERE role = 'agency'";
    $users_result = $conn->query($users_query);
    
    echo "Total agency users: " . $users_result->num_rows . "\n";
    while ($user = $users_result->fetch_assoc()) {
        echo "User ID: " . $user['id'] . ", Username: " . $user['username'] . "\n";
    }
    
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}

$conn->close();
?> 