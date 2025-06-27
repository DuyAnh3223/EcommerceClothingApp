<?php
// Database configuration
define('DB_HOST', 'localhost');
define('DB_NAME', 'clothing_appstore');
define('DB_USER', 'root');
define('DB_PASS', '');

// Create mysqli connection
$conn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);

// Check connection
if ($conn->connect_error) {
    die(json_encode(["success" => false, "message" => "Connection failed: " . $conn->connect_error]));
}

// Set charset
$conn->set_charset("utf8mb4");
?>
