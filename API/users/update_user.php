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
    $username = $input['username'] ?? null;
    $email = $input['email'] ?? null;
    $phone = $input['phone'] ?? null;
    $gender = $input['gender'] ?? null;
    $dob = $input['dob'] ?? null;
    
    if (!$userId) {
        sendResponse(false, 'User ID is required', null, 400);
        exit();
    }
    
    // Validate email format if provided
    if ($email && !filter_var($email, FILTER_VALIDATE_EMAIL)) {
        sendResponse(false, 'Invalid email format', null, 400);
        exit();
    }
    
    // Validate phone format if provided
    if ($phone && !preg_match('/^[0-9]{10,11}$/', $phone)) {
        sendResponse(false, 'Invalid phone format', null, 400);
        exit();
    }
    
    // Validate gender if provided
    if ($gender !== null && !in_array($gender, ['male', 'female'])) {
        sendResponse(false, 'Gender must be either "male" or "female"', null, 400);
        exit();
    }
    
    // Check if email already exists for other users
    if ($email) {
        $stmt = $conn->prepare("SELECT id FROM users WHERE email = ? AND id != ?");
        $stmt->bind_param("si", $email, $userId);
        $stmt->execute();
        $result = $stmt->get_result();
        if ($result->fetch_assoc()) {
            sendResponse(false, 'Email already exists', null, 400);
            exit();
        }
        $stmt->close();
    }
    
    // Check if phone already exists for other users
    if ($phone) {
        $stmt = $conn->prepare("SELECT id FROM users WHERE phone = ? AND id != ?");
        $stmt->bind_param("si", $phone, $userId);
        $stmt->execute();
        $result = $stmt->get_result();
        if ($result->fetch_assoc()) {
            sendResponse(false, 'Phone already exists', null, 400);
            exit();
        }
        $stmt->close();
    }
    
    // Build update query
    $updateFields = [];
    $types = '';
    $params = [];
    
    if ($username !== null) {
        $updateFields[] = "username = ?";
        $types .= 's';
        $params[] = $username;
    }
    
    if ($email !== null) {
        $updateFields[] = "email = ?";
        $types .= 's';
        $params[] = $email;
    }
    
    if ($phone !== null) {
        $updateFields[] = "phone = ?";
        $types .= 's';
        $params[] = $phone;
    }
    
    if ($gender !== null) {
        $updateFields[] = "gender = ?";
        $types .= 's';
        $params[] = $gender;
    }
    
    if ($dob !== null) {
        $updateFields[] = "dob = ?";
        $types .= 's';
        $params[] = $dob;
    }
    
    if (empty($updateFields)) {
        sendResponse(false, 'No fields to update', null, 400);
        exit();
    }
    
    $updateFields[] = "updated_at = CURRENT_TIMESTAMP";
    $types .= 'i';
    $params[] = $userId;
    
    $sql = "UPDATE users SET " . implode(', ', $updateFields) . " WHERE id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param($types, ...$params);
    $result = $stmt->execute();
    
    if ($result) {
        // Get updated user data
        $stmt = $conn->prepare("SELECT id, username, email, phone, gender, dob, role, created_at, updated_at FROM users WHERE id = ?");
        $stmt->bind_param("i", $userId);
        $stmt->execute();
        $result = $stmt->get_result();
        $userData = $result->fetch_assoc();
        $stmt->close();
        
        sendResponse(true, 'User profile updated successfully', $userData);
    } else {
        sendResponse(false, 'Failed to update user profile', null, 500);
    }
    $stmt->close();
    
} catch (Exception $e) {
    sendResponse(false, 'Server error: ' . $e->getMessage(), null, 500);
}
?>
