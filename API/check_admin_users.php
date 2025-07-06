<?php
include_once 'config/db_connect.php';

echo "=== Checking Admin Users ===\n";
$result = $conn->query("SELECT id, username, role FROM users WHERE role = 'admin'");
if ($result && $result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        echo "ID: " . $row['id'] . ", Username: " . $row['username'] . ", Role: " . $row['role'] . "\n";
    }
} else {
    echo "No admin users found\n";
}

echo "\n=== All Users ===\n";
$result = $conn->query("SELECT id, username, role FROM users");
if ($result && $result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        echo "ID: " . $row['id'] . ", Username: " . $row['username'] . ", Role: " . $row['role'] . "\n";
    }
}
?> 