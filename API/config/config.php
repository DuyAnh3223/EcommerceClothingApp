<?php
// Database configuration
define('DB_HOST', '127.0.0.1');
define('DB_NAME', 'clothing_appstore');
define('DB_USER', 'root');
define('DB_PASS', '');

// BACoin configuration
define('ADMIN_USER_ID', 6); // ID của admin user
define('AGENCY_PLATFORM_FEE_RATE', 20); // Phí sàn cho agency (20%)

// Create mysqli connection
$conn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);

// Check connection
if ($conn->connect_error) {
    die(json_encode(["success" => false, "message" => "Connection failed: " . $conn->connect_error]));
}

// Set charset
$conn->set_charset("utf8mb4");
?>
