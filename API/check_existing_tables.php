<?php
// Check what tables actually exist
require_once 'config/db_connect.php';

echo "=== EXISTING TABLES CHECK ===\n\n";

$result = $conn->query("SHOW TABLES");
if ($result) {
    echo "Tables in database:\n";
    while ($row = $result->fetch_array()) {
        echo "- {$row[0]}\n";
    }
} else {
    echo "Error: " . $conn->error . "\n";
}

echo "\n=== CHECK COMPLETE ===\n";
?> 