<?php
include_once 'config/db_connect.php';
include_once 'utils/auth.php';

echo "=== Debug Authentication ===\n";

// Test authenticate function
$user = authenticate();
if ($user) {
    echo "Authenticated user:\n";
    echo "ID: " . $user['id'] . "\n";
    echo "Role: " . $user['role'] . "\n";
    
    // Check if this user exists in database
    $stmt = $conn->prepare("SELECT id, username, role FROM users WHERE id = ?");
    $stmt->bind_param("i", $user['id']);
    $stmt->execute();
    $result = $stmt->get_result();
    if ($result->num_rows > 0) {
        $db_user = $result->fetch_assoc();
        echo "Database user: " . $db_user['username'] . " (ID: " . $db_user['id'] . ", Role: " . $db_user['role'] . ")\n";
    } else {
        echo "User not found in database!\n";
    }
} else {
    echo "No user authenticated\n";
}

echo "\n=== All Agency Users ===\n";
$result = $conn->query("SELECT id, username, role FROM users WHERE role = 'agency'");
if ($result && $result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        echo "ID: " . $row['id'] . ", Username: " . $row['username'] . ", Role: " . $row['role'] . "\n";
    }
} else {
    echo "No agency users found\n";
}

echo "\n=== All Users ===\n";
$result = $conn->query("SELECT id, username, role FROM users");
if ($result && $result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        echo "ID: " . $row['id'] . ", Username: " . $row['username'] . ", Role: " . $row['role'] . "\n";
    }
}
?> 