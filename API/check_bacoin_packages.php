<?php
include_once 'config/db_connect.php';

echo "=== Checking BACoin Packages ===\n";
$result = $conn->query("SELECT * FROM bacoin_packages ORDER BY price_vnd ASC");
if ($result && $result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        echo "ID: " . $row['id'] . ", Name: " . $row['package_name'] . ", Price: " . $row['price_vnd'] . ", BACoin: " . $row['bacoin_amount'] . "\n";
    }
} else {
    echo "No BACoin packages found\n";
}

echo "\n=== Checking Admin Users ===\n";
$result = $conn->query("SELECT id, username, role FROM users WHERE role = 'admin'");
if ($result && $result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        echo "ID: " . $row['id'] . ", Username: " . $row['username'] . ", Role: " . $row['role'] . "\n";
    }
} else {
    echo "No admin users found\n";
}
?> 