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
    
    $userId = $input['user_id'] ?? null;
    $addressLine = $input['address_line'] ?? null;
    $city = $input['city'] ?? null;
    $province = $input['province'] ?? null;
    $postalCode = $input['postal_code'] ?? null;
    $isDefault = $input['is_default'] ?? false;
    
    // Validate required fields
    if (!$userId || !$addressLine || !$city || !$province) {
        sendResponse(false, 'User ID, address line, city, and province are required', null, 400);
        exit();
    }
    
    // If this is the first address or marked as default, set other addresses to non-default
    if ($isDefault) {
        $stmt = $conn->prepare("UPDATE user_addresses SET is_default = 0 WHERE user_id = ?");
        $stmt->bind_param("i", $userId);
        $stmt->execute();
        $stmt->close();
    }
    
    // Insert new address
    $sql = "INSERT INTO user_addresses (user_id, address_line, city, province, postal_code, is_default) VALUES (?, ?, ?, ?, ?, ?)";
    $stmt = $conn->prepare($sql);
    $isDefaultInt = $isDefault ? 1 : 0;
    $stmt->bind_param("issssi", $userId, $addressLine, $city, $province, $postalCode, $isDefaultInt);
    $result = $stmt->execute();
    
    if ($result) {
        $addressId = $conn->insert_id;
        
        // Get the created address
        $stmt = $conn->prepare("SELECT * FROM user_addresses WHERE id = ?");
        $stmt->bind_param("i", $addressId);
        $stmt->execute();
        $result = $stmt->get_result();
        $addressData = $result->fetch_assoc();
        $stmt->close();
        
        sendResponse(true, 'Address added successfully', $addressData);
    } else {
        sendResponse(false, 'Failed to add address', null, 500);
    }
    $stmt->close();
    
} catch (Exception $e) {
    sendResponse(false, 'Server error: ' . $e->getMessage(), null, 500);
}
?> 