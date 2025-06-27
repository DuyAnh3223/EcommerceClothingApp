<?php
require_once '../config/config.php';
require_once '../utils/response.php';
require_once '../utils/auth.php';

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
    // Get JSON input
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input) {
        sendResponse(false, 'Invalid JSON input', null, 400);
        exit();
    }
    
    $addressId = $input['address_id'] ?? null;
    $userId = $input['user_id'] ?? null;
    
    // Validate required fields
    if (!$addressId || !$userId) {
        sendResponse(false, 'Address ID and User ID are required', null, 400);
        exit();
    }
    
    // Check if address belongs to user
    $stmt = $conn->prepare("SELECT id, is_default FROM user_addresses WHERE id = ? AND user_id = ?");
    $stmt->bind_param("ii", $addressId, $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    $address = $result->fetch_assoc();
    $stmt->close();
    
    if (!$address) {
        sendResponse(false, 'Address not found or does not belong to user', null, 404);
        exit();
    }
    
    // Check if this is the default address
    $isDefault = $address['is_default'] == 1;
    
    // Delete the address
    $stmt = $conn->prepare("DELETE FROM user_addresses WHERE id = ? AND user_id = ?");
    $stmt->bind_param("ii", $addressId, $userId);
    $result = $stmt->execute();
    $stmt->close();
    
    if ($result) {
        // If this was the default address, set another address as default
        if ($isDefault) {
            $stmt = $conn->prepare("SELECT id FROM user_addresses WHERE user_id = ? ORDER BY created_at ASC LIMIT 1");
            $stmt->bind_param("i", $userId);
            $stmt->execute();
            $result = $stmt->get_result();
            $newDefault = $result->fetch_assoc();
            $stmt->close();
            
            if ($newDefault) {
                $stmt = $conn->prepare("UPDATE user_addresses SET is_default = 1 WHERE id = ?");
                $stmt->bind_param("i", $newDefault['id']);
                $stmt->execute();
                $stmt->close();
            }
        }
        
        sendResponse(true, 'Address deleted successfully', null);
    } else {
        sendResponse(false, 'Failed to delete address', null, 500);
    }
    
} catch (Exception $e) {
    sendResponse(false, 'Server error: ' . $e->getMessage(), null, 500);
}
?> 