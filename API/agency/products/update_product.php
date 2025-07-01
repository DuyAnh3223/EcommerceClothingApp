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

if ($_SERVER['REQUEST_METHOD'] !== 'PUT') {
    sendResponse(false, 'Method not allowed', null, 405);
    exit();
}

try {
    $data = json_decode(file_get_contents("php://input"), true);
    
    // Validate required fields
    if (!isset($data['product_id'])) {
        sendResponse(false, 'Product ID is required', null, 400);
        exit();
    }
    
    $product_id = intval($data['product_id']);
    
    // Check if product exists and belongs to this agency
    $stmt = $conn->prepare("
        SELECT id, status FROM products 
        WHERE id = ? AND created_by = ? AND is_agency_product = 1
    ");
    $stmt->bind_param("ii", $product_id, $user['id']);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        sendResponse(false, 'Product not found or access denied', null, 404);
        exit();
    }
    
    $product = $result->fetch_assoc();
    
    // Check if product can be updated (not in pending or approved status)
    if (in_array($product['status'], ['pending', 'approved'])) {
        sendResponse(false, 'Cannot update product in pending or approved status', null, 400);
        exit();
    }
    
    // Prepare update fields
    $update_fields = [];
    $params = [];
    $types = "";
    
    if (isset($data['name'])) {
        $name = trim($data['name']);
        if (empty($name)) {
            sendResponse(false, 'Product name cannot be empty', null, 400);
            exit();
        }
        if (strlen($name) > 100) {
            sendResponse(false, 'Product name must be less than 100 characters', null, 400);
            exit();
        }
        $update_fields[] = "name = ?";
        $params[] = $name;
        $types .= "s";
    }
    
    if (isset($data['description'])) {
        $description = trim($data['description']);
        $update_fields[] = "description = ?";
        $params[] = $description;
        $types .= "s";
    }
    
    if (isset($data['category'])) {
        $category = trim($data['category']);
        if (empty($category)) {
            sendResponse(false, 'Category cannot be empty', null, 400);
            exit();
        }
        $update_fields[] = "category = ?";
        $params[] = $category;
        $types .= "s";
    }
    
    if (isset($data['gender_target'])) {
        $gender_target = trim($data['gender_target']);
        if (!in_array($gender_target, ['male', 'female', 'unisex'])) {
            sendResponse(false, 'Invalid gender target. Must be male, female, or unisex', null, 400);
            exit();
        }
        $update_fields[] = "gender_target = ?";
        $params[] = $gender_target;
        $types .= "s";
    }
    
    if (isset($data['main_image'])) {
        $main_image = $data['main_image'];
        $update_fields[] = "main_image = ?";
        $params[] = $main_image;
        $types .= "s";
    }
    
    if (empty($update_fields)) {
        sendResponse(false, 'No fields to update', null, 400);
        exit();
    }
    
    // Add product_id to params
    $params[] = $product_id;
    $types .= "i";
    
    // Update product
    $sql = "UPDATE products SET " . implode(", ", $update_fields) . ", updated_at = NOW() WHERE id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param($types, ...$params);
    
    if ($stmt->execute()) {
        sendResponse(true, 'Product updated successfully', [
            'product_id' => $product_id
        ], 200);
    } else {
        sendResponse(false, 'Failed to update product', null, 500);
    }
    
} catch (Exception $e) {
    sendResponse(false, 'Server error: ' . $e->getMessage(), null, 500);
}

$conn->close();
?> 