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
    if (!isset($data['name']) || !isset($data['description']) || !isset($data['category']) || !isset($data['gender_target'])) {
        sendResponse(false, 'Missing required fields: name, description, category, gender_target', null, 400);
        exit();
    }
    
    $name = trim($data['name']);
    $description = trim($data['description']);
    $category = trim($data['category']);
    $gender_target = trim($data['gender_target']);
    $main_image = $data['main_image'] ?? null;
    
    // Validate data
    if (empty($name) || empty($description) || empty($category) || empty($gender_target)) {
        sendResponse(false, 'All fields are required', null, 400);
        exit();
    }
    
    if (strlen($name) > 100) {
        sendResponse(false, 'Product name must be less than 100 characters', null, 400);
        exit();
    }
    
    if (!in_array($gender_target, ['male', 'female', 'unisex'])) {
        sendResponse(false, 'Invalid gender target. Must be male, female, or unisex', null, 400);
        exit();
    }
    
    $conn->begin_transaction();
    
    // Insert product
    $stmt = $conn->prepare("
        INSERT INTO products (name, description, category, gender_target, main_image, created_by, is_agency_product, status, platform_fee_rate) 
        VALUES (?, ?, ?, ?, ?, ?, 1, 'inactive', 20.00)
    ");
    $stmt->bind_param("sssssi", $name, $description, $category, $gender_target, $main_image, $user['id']);
    
    if ($stmt->execute()) {
        $product_id = $conn->insert_id;
        
        // Create product approval record
        $stmt = $conn->prepare("
            INSERT INTO product_approvals (product_id, status) 
            VALUES (?, 'inactive')
        ");
        $stmt->bind_param("i", $product_id);
        $stmt->execute();
        
        $conn->commit();
        
        sendResponse(true, 'Product added successfully', [
            'product_id' => $product_id,
            'name' => $name,
            'status' => 'inactive'
        ], 201);
    } else {
        $conn->rollback();
        sendResponse(false, 'Failed to add product', null, 500);
    }
    
} catch (Exception $e) {
    if (isset($conn)) {
        $conn->rollback();
    }
    sendResponse(false, 'Server error: ' . $e->getMessage(), null, 500);
}

$conn->close();
?> 