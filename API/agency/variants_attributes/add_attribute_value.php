<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Content-Type: application/json');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

include_once '../../config/db_connect.php';
include_once '../../utils/response.php';
include_once '../../utils/auth.php';

// Check if user is agency
$user = authenticate();
if (!$user || $user['role'] !== 'agency') {
    sendResponse(false, 'Access denied. Agency role required.', null, 403);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(false, 'Method not allowed', null, 405);
    exit();
}

try {
    $data = json_decode(file_get_contents("php://input"), true);
    
    // Validate required fields
    if (!isset($data['attribute_id']) || !isset($data['value'])) {
        sendResponse(false, 'Attribute ID and value are required', null, 400);
        exit();
    }
    
    $attribute_id = intval($data['attribute_id']);
    $value = trim($data['value']);
    
    // Validate data
    if (empty($value)) {
        sendResponse(false, 'Attribute value cannot be empty', null, 400);
        exit();
    }
    
    if (strlen($value) > 50) {
        sendResponse(false, 'Attribute value must be less than 50 characters', null, 400);
        exit();
    }
    
    // Check if attribute exists
    $stmt = $conn->prepare("SELECT id FROM attributes WHERE id = ?");
    $stmt->bind_param("i", $attribute_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        sendResponse(false, 'Attribute not found', null, 404);
        exit();
    }
    
    // Check if value already exists for this attribute
    $stmt = $conn->prepare("SELECT id FROM attribute_values WHERE attribute_id = ? AND value = ?");
    $stmt->bind_param("is", $attribute_id, $value);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        sendResponse(false, 'Attribute value already exists', null, 409);
        exit();
    }
    
    // Insert attribute value
    $stmt = $conn->prepare("INSERT INTO attribute_values (attribute_id, value, created_by) VALUES (?, ?, ?)");
    $stmt->bind_param("isi", $attribute_id, $value, $user['id']);
    
    if ($stmt->execute()) {
        $value_id = $conn->insert_id;
        
        sendResponse(true, 'Attribute value added successfully', [
            'value_id' => $value_id,
            'attribute_id' => $attribute_id,
            'value' => $value
        ], 201);
    } else {
        sendResponse(false, 'Failed to add attribute value', null, 500);
    }
    
} catch (Exception $e) {
    sendResponse(false, 'Server error: ' . $e->getMessage(), null, 500);
}

$conn->close();
?> 