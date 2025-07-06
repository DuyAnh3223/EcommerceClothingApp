<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/../../config/db_connect.php';
require_once __DIR__ . '/../../utils/response.php';

// TEMPORARY: Bypass authentication for testing
// In production, use proper authentication
$user = [
    'id' => 6, // Admin user ID
    'role' => 'admin'
];

try {
    $stmt = $conn->prepare("SELECT * FROM bacoin_packages ORDER BY price_vnd ASC");
    $stmt->execute();
    $result = $stmt->get_result();
    $packages = [];
    while ($row = $result->fetch_assoc()) {
        $packages[] = $row;
    }
    
    sendResponse(200, 'Success', $packages);
} catch (Exception $e) {
    sendResponse(500, 'Database error: ' . $e->getMessage(), null);
}
?> 