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
    $addressLine = $input['address_line'] ?? null;
    $city = $input['city'] ?? null;
    $province = $input['province'] ?? null;
    $postalCode = $input['postal_code'] ?? null;
    $isDefault = $input['is_default'] ?? null;
    
    // Validate required fields
    if (!$addressId || !$userId) {
        sendResponse(false, 'Address ID and User ID are required', null, 400);
        exit();
    }
    
    // Check if address belongs to user
    $stmt = $conn->prepare("SELECT id FROM user_addresses WHERE id = ? AND user_id = ?");
    $stmt->bind_param("ii", $addressId, $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    if (!$result->fetch_assoc()) {
        sendResponse(false, 'Address not found or does not belong to user', null, 404);
        exit();
    }
    $stmt->close();
    
    // If setting as default, set other addresses to non-default
    if ($isDefault) {
        $stmt = $conn->prepare("UPDATE user_addresses SET is_default = 0 WHERE user_id = ? AND id != ?");
        $stmt->bind_param("ii", $userId, $addressId);
        $stmt->execute();
        $stmt->close();
    }
    
    // Build update query
    $updateFields = [];
    $types = '';
    $params = [];
    
    if ($addressLine !== null) {
        $updateFields[] = "address_line = ?";
        $types .= 's';
        $params[] = $addressLine;
    }
    
    if ($city !== null) {
        $updateFields[] = "city = ?";
        $types .= 's';
        $params[] = $city;
    }
    
    if ($province !== null) {
        $updateFields[] = "province = ?";
        $types .= 's';
        $params[] = $province;
    }
    
    if ($postalCode !== null) {
        $updateFields[] = "postal_code = ?";
        $types .= 's';
        $params[] = $postalCode;
    }
    
    if ($isDefault !== null) {
        $updateFields[] = "is_default = ?";
        $types .= 'i';
        $params[] = $isDefault ? 1 : 0;
    }
    
    if (empty($updateFields)) {
        sendResponse(false, 'No fields to update', null, 400);
        exit();
    }
    
    $types .= 'ii';
    $params[] = $addressId;
    $params[] = $userId;
    
    $sql = "UPDATE user_addresses SET " . implode(', ', $updateFields) . " WHERE id = ? AND user_id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param($types, ...$params);
    $result = $stmt->execute();
    
    if ($result) {
        // Get updated address data
        $stmt = $conn->prepare("SELECT * FROM user_addresses WHERE id = ?");
        $stmt->bind_param("i", $addressId);
        $stmt->execute();
        $result = $stmt->get_result();
        $addressData = $result->fetch_assoc();
        $stmt->close();
        
        sendResponse(true, 'Address updated successfully', $addressData);
    } else {
        sendResponse(false, 'Failed to update address', null, 500);
    }
    $stmt->close();
    
} catch (Exception $e) {
    sendResponse(false, 'Server error: ' . $e->getMessage(), null, 500);
}
?> 