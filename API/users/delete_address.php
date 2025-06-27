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
    if (!is_numeric($addressId)) {
        sendResponse(false, 'Address ID is required', null, 400);
        exit();
    }
    $addressId = (int)$addressId;
    // Lấy thông tin địa chỉ
    $stmt = $conn->prepare("SELECT id, user_id, is_default FROM user_addresses WHERE id = ?");
    $stmt->bind_param("i", $addressId);
    $stmt->execute();
    $result = $stmt->get_result();
    $address = $result->fetch_assoc();
    $stmt->close();
    if (!$address) {
        sendResponse(false, 'Address not found', null, 404);
        exit();
    }
    $userId = $address['user_id'];
    $isDefault = $address['is_default'] == 1;
    // Xóa địa chỉ
    $stmt = $conn->prepare("DELETE FROM user_addresses WHERE id = ?");
    $stmt->bind_param("i", $addressId);
    $result = $stmt->execute();
    $stmt->close();
    if ($result) {
        // Nếu là địa chỉ mặc định, gán địa chỉ khác làm mặc định
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