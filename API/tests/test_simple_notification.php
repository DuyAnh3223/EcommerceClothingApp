<?php
require_once 'config/config.php';
require_once 'utils/response.php';

// Set CORS headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    // Test GET request
    sendResponse(true, 'API is working', [
        'message' => 'Notification API is accessible',
        'timestamp' => date('Y-m-d H:i:s')
    ]);
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        // Get JSON input
        $input = json_decode(file_get_contents('php://input'), true);
        
        if (!$input) {
            sendResponse(false, 'Invalid JSON input', null, 400);
            exit();
        }
        
        $userId = $input['user_id'] ?? null;
        $title = $input['title'] ?? 'Test notification';
        $content = $input['content'] ?? 'This is a test notification';
        $type = $input['type'] ?? 'other';
        
        if (!$userId) {
            sendResponse(false, 'User ID is required', null, 400);
            exit();
        }
        
        // Test database connection
        $conn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);
        
        if ($conn->connect_error) {
            sendResponse(false, 'Database connection failed: ' . $conn->connect_error, null, 500);
            exit();
        }
        
        // Check if user exists
        $checkUser = $conn->prepare("SELECT id, username FROM users WHERE id = ?");
        $checkUser->bind_param("i", $userId);
        $checkUser->execute();
        $userResult = $checkUser->get_result();
        $user = $userResult->fetch_assoc();
        
        if (!$user) {
            sendResponse(false, 'User not found', null, 404);
            exit();
        }
        
        // Insert test notification
        $sql = "INSERT INTO notifications (user_id, title, content, type, is_read) VALUES (?, ?, ?, ?, 0)";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("isss", $userId, $title, $content, $type);
        $result = $stmt->execute();
        
        if ($result) {
            $notificationId = $conn->insert_id;
            $stmt->close();
            $checkUser->close();
            $conn->close();
            
            sendResponse(true, 'Test notification created successfully', [
                'notification_id' => $notificationId,
                'user_id' => $userId,
                'username' => $user['username'],
                'title' => $title,
                'content' => $content,
                'type' => $type
            ]);
        } else {
            sendResponse(false, 'Failed to create notification: ' . $conn->error, null, 500);
        }
        
    } catch (Exception $e) {
        sendResponse(false, 'Server error: ' . $e->getMessage(), null, 500);
    }
}

sendResponse(false, 'Method not allowed', null, 405);
?> 