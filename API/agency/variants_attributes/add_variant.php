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
    if (!isset($data['product_id']) || !isset($data['price']) || !isset($data['stock']) || !isset($data['attribute_values'])) {
        sendResponse(false, 'Missing required fields: product_id, price, stock, attribute_values', null, 400);
        exit();
    }
    
    $product_id = intval($data['product_id']);
    $price = floatval($data['price']);
    $stock = intval($data['stock']);
    $image_url = $data['image_url'] ?? null;
    $attribute_values = $data['attribute_values']; // Array of attribute_value_ids
    
    // Validate data
    if ($price <= 0) {
        sendResponse(false, 'Price must be greater than 0', null, 400);
        exit();
    }
    
    if ($stock < 0) {
        sendResponse(false, 'Stock cannot be negative', null, 400);
        exit();
    }
    
    if (!is_array($attribute_values) || empty($attribute_values)) {
        sendResponse(false, 'At least one attribute value is required', null, 400);
        exit();
    }
    
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
    
    // Check if product can be modified (not in pending or approved status)
    if (in_array($product['status'], ['pending', 'approved'])) {
        sendResponse(false, 'Cannot modify product in pending or approved status', null, 400);
        exit();
    }
    
    // Validate attribute values exist
    $placeholders = str_repeat('?,', count($attribute_values) - 1) . '?';
    $stmt = $conn->prepare("SELECT id FROM attribute_values WHERE id IN ($placeholders)");
    $stmt->bind_param(str_repeat('i', count($attribute_values)), ...$attribute_values);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows !== count($attribute_values)) {
        sendResponse(false, 'One or more attribute values not found', null, 400);
        exit();
    }
    
    $conn->begin_transaction();
    
    // Generate SKU
    $sku = 'AGENCY-' . $product_id . '-' . uniqid();
    
    // Insert variant
    $stmt = $conn->prepare("INSERT INTO variants (sku) VALUES (?)");
    $stmt->bind_param("s", $sku);
    $stmt->execute();
    $variant_id = $conn->insert_id;
    
    // Insert product variant
    $stmt = $conn->prepare("
        INSERT INTO product_variant (product_id, variant_id, price, stock, image_url, status) 
        VALUES (?, ?, ?, ?, ?, 'active')
    ");
    $stmt->bind_param("iidss", $product_id, $variant_id, $price, $stock, $image_url);
    
    if ($stmt->execute()) {
        // Insert variant attribute values
        foreach ($attribute_values as $value_id) {
            $stmt = $conn->prepare("INSERT INTO variant_attribute_values (variant_id, attribute_value_id) VALUES (?, ?)");
            $stmt->bind_param("ii", $variant_id, $value_id);
            $stmt->execute();
        }
        
        $conn->commit();
        
        sendResponse(true, 'Variant added successfully', [
            'variant_id' => $variant_id,
            'product_id' => $product_id,
            'sku' => $sku,
            'price' => $price,
            'stock' => $stock
        ], 201);
    } else {
        $conn->rollback();
        sendResponse(false, 'Failed to add variant', null, 500);
    }
    
} catch (Exception $e) {
    if (isset($conn)) {
        $conn->rollback();
    }
    sendResponse(false, 'Server error: ' . $e->getMessage(), null, 500);
}

$conn->close();
?> 