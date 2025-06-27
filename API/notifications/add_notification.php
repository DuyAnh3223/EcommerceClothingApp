<?php
require_once '../config/config.php';
require_once '../utils/response.php';

// Set CORS headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(false, 'Method not allowed', null, 405);
    exit();
}

try {
    $conn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);
    
    if ($conn->connect_error) {
        sendResponse(false, 'Connection failed: ' . $conn->connect_error, null, 500);
        exit();
    }
    
    // Get JSON input
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input) {
        sendResponse(false, 'Invalid JSON input', null, 400);
        exit();
    }
    
    $userId = $input['user_id'] ?? null;
    $title = $input['title'] ?? null;
    $content = $input['content'] ?? null;
    $type = $input['type'] ?? 'other';
    
    if (!$userId || !$title) {
        sendResponse(false, 'User ID and title are required', null, 400);
        exit();
    }
    
    // Validate type
    $allowedTypes = ['order_status', 'sale', 'voucher', 'other'];
    if (!in_array($type, $allowedTypes)) {
        sendResponse(false, 'Invalid notification type', null, 400);
        exit();
    }
    
    // Check if user exists
    $checkUser = $conn->prepare("SELECT id FROM users WHERE id = ?");
    $checkUser->bind_param("i", $userId);
    $checkUser->execute();
    $userResult = $checkUser->get_result();
    
    if (!$userResult->fetch_assoc()) {
        sendResponse(false, 'User not found', null, 404);
        exit();
    }
    $checkUser->close();
    
    // Insert notification
    $sql = "INSERT INTO notifications (user_id, title, content, type, is_read) VALUES (?, ?, ?, ?, 0)";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("isss", $userId, $title, $content, $type);
    $result = $stmt->execute();
    
    if ($result) {
        $notificationId = $conn->insert_id;
        $stmt->close();
        $conn->close();
        
        sendResponse(true, 'Notification created successfully', [
            'id' => $notificationId,
            'user_id' => $userId,
            'title' => $title,
            'content' => $content,
            'type' => $type,
            'is_read' => false
        ]);
    } else {
        sendResponse(false, 'Failed to create notification', null, 500);
    }
    
} catch (Exception $e) {
    sendResponse(false, 'Server error: ' . $e->getMessage(), null, 500);
}
?>
