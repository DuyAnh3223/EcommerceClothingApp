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
    if (!isset($data['name'])) {
        sendResponse(false, 'Attribute name is required', null, 400);
        exit();
    }
    
    $name = trim($data['name']);
    
    // Validate data
    if (empty($name)) {
        sendResponse(false, 'Attribute name cannot be empty', null, 400);
        exit();
    }
    
    if (strlen($name) > 50) {
        sendResponse(false, 'Attribute name must be less than 50 characters', null, 400);
        exit();
    }
    
    // Check if attribute already exists
    $stmt = $conn->prepare("SELECT id FROM attributes WHERE name = ?");
    $stmt->bind_param("s", $name);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        sendResponse(false, 'Attribute already exists', null, 409);
        exit();
    }
    
    // Insert attribute
    $stmt = $conn->prepare("INSERT INTO attributes (name, created_by) VALUES (?, ?)");
    $stmt->bind_param("si", $name, $user['id']);
    
    if ($stmt->execute()) {
        $attribute_id = $conn->insert_id;
        
        sendResponse(true, 'Attribute added successfully', [
            'attribute_id' => $attribute_id,
            'name' => $name
        ], 201);
    } else {
        sendResponse(false, 'Failed to add attribute: ' . $stmt->error, null, 500);
    }
    
} catch (Exception $e) {
    sendResponse(false, 'Server error: ' . $e->getMessage(), null, 500);
}

$conn->close();
?> 