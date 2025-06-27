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
    $notificationId = $input['notification_id'] ?? null;
    $markAll = $input['mark_all'] ?? false;
    
    if (!$userId) {
        sendResponse(false, 'User ID is required', null, 400);
        exit();
    }
    
    if ($markAll) {
        // Mark all notifications as read for the user
        $sql = "UPDATE notifications SET is_read = 1 WHERE user_id = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("i", $userId);
        $result = $stmt->execute();
        
        if ($result) {
            $affectedRows = $stmt->affected_rows;
            $stmt->close();
            $conn->close();
            
            sendResponse(true, "Marked $affectedRows notifications as read", [
                'affected_rows' => $affectedRows
            ]);
        } else {
            sendResponse(false, 'Failed to mark notifications as read', null, 500);
        }
    } else {
        // Mark specific notification as read
        if (!$notificationId) {
            sendResponse(false, 'Notification ID is required when not marking all', null, 400);
            exit();
        }
        
        $sql = "UPDATE notifications SET is_read = 1 WHERE id = ? AND user_id = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("ii", $notificationId, $userId);
        $result = $stmt->execute();
        
        if ($result) {
            $affectedRows = $stmt->affected_rows;
            $stmt->close();
            $conn->close();
            
            if ($affectedRows > 0) {
                sendResponse(true, 'Notification marked as read', [
                    'affected_rows' => $affectedRows
                ]);
            } else {
                sendResponse(false, 'Notification not found or already read', null, 404);
            }
        } else {
            sendResponse(false, 'Failed to mark notification as read', null, 500);
        }
    }
    
} catch (Exception $e) {
    sendResponse(false, 'Server error: ' . $e->getMessage(), null, 500);
}
?>
