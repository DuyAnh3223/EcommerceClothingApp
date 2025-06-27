<?php
require_once '../config/config.php';
require_once '../utils/response.php';

// Set CORS headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    sendResponse(false, 'Method not allowed', null, 405);
    exit();
}

try {
    $conn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);
    
    if ($conn->connect_error) {
        sendResponse(false, 'Connection failed: ' . $conn->connect_error, null, 500);
        exit();
    }
    
    $userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
    
    if (!$userId) {
        sendResponse(false, 'User ID is required', null, 400);
        exit();
    }
    
    $sql = "SELECT COUNT(*) as unread_count FROM notifications WHERE user_id = ? AND is_read = 0";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    $count = $result->fetch_assoc()['unread_count'];
    
    $stmt->close();
    $conn->close();
    
    sendResponse(true, 'Unread count retrieved successfully', [
        'unread_count' => (int)$count
    ]);
    
} catch (Exception $e) {
    sendResponse(false, 'Server error: ' . $e->getMessage(), null, 500);
}
?> 