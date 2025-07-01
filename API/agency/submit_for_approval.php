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

require_once '../config/db_connect.php';
require_once '../utils/response.php';
require_once '../utils/auth.php';

// Check if user is agency
$user = authenticate();
if (!$user || $user['role'] !== 'agency') {
    sendResponse(false, 'Access denied. Agency role required.', null, 403);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(false, 'Method not allowed', null, 405);
}

try {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($input['product_id'])) {
        sendResponse(false, 'Product ID is required', null, 400);
    }
    
    $productId = intval($input['product_id']);
    
    // Check if product exists and belongs to agency
    $stmt = $conn->prepare("
        SELECT p.*, u.role 
        FROM products p 
        JOIN users u ON p.created_by = u.id 
        WHERE p.id = ? AND p.is_agency_product = 1
    ");
    $stmt->bind_param("i", $productId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        sendResponse(false, 'Product not found or not an agency product', null, 404);
    }
    
    $product = $result->fetch_assoc();
    
    // Check if user is agency
    if ($product['role'] !== 'agency') {
        sendResponse(false, 'Only agency can submit products for approval', null, 403);
    }
    
    // Check if product is in inactive or rejected status
    if (!in_array($product['status'], ['inactive', 'rejected'])) {
        sendResponse(false, 'Product can only be submitted when in inactive or rejected status', null, 400);
    }
    
    // Check if product has complete information
    if (empty($product['name']) || empty($product['category']) || empty($product['gender_target'])) {
        sendResponse(false, 'Product must have complete information (name, category, gender_target)', null, 400);
    }
    
    if (empty($product['main_image'])) {
        sendResponse(false, 'Product must have a main image', null, 400);
    }
    
    // Check if product has variants with complete information
    $stmt = $conn->prepare("
        SELECT pv.*, v.sku
        FROM product_variant pv
        JOIN variants v ON pv.variant_id = v.id
        WHERE pv.product_id = ?
    ");
    $stmt->bind_param("i", $productId);
    $stmt->execute();
    $variantsResult = $stmt->get_result();
    
    if ($variantsResult->num_rows === 0) {
        sendResponse(false, 'Product must have at least one variant before submission', null, 400);
    }
    
    // Validate each variant
    $validVariants = 0;
    while ($variant = $variantsResult->fetch_assoc()) {
        // Check if variant has complete information
        if (empty($variant['sku']) || 
            $variant['price'] <= 0 || 
            $variant['stock'] <= 0 || 
            $variant['status'] !== 'active') {
            continue;
        }
        
        // Check if variant has attributes
        $stmt2 = $conn->prepare("
            SELECT COUNT(*) as attr_count 
            FROM variant_attribute_values 
            WHERE variant_id = ?
        ");
        $stmt2->bind_param("i", $variant['variant_id']);
        $stmt2->execute();
        $attrResult = $stmt2->get_result();
        $attrCount = $attrResult->fetch_assoc()['attr_count'];
        
        if ($attrCount > 0) {
            $validVariants++;
        }
    }
    
    if ($validVariants === 0) {
        sendResponse(false, 'Product must have at least one valid variant with complete information and attributes', null, 400);
    }
    
    $conn->begin_transaction();
    
    // Update product status to pending
    $stmt = $conn->prepare("
        UPDATE products 
        SET status = 'pending', updated_at = NOW() 
        WHERE id = ?
    ");
    $stmt->bind_param("i", $productId);
    
    if ($stmt->execute()) {
        // Create or update product approval record
        $stmt = $conn->prepare("
            INSERT INTO product_approvals (product_id, status, created_at) 
            VALUES (?, 'pending', NOW()) 
            ON DUPLICATE KEY UPDATE 
            status = 'pending', 
            reviewed_by = NULL, 
            review_notes = NULL, 
            reviewed_at = NULL, 
            created_at = NOW()
        ");
        $stmt->bind_param("i", $productId);
        $stmt->execute();
        
        // Send notification to admin
        $adminUsers = $conn->query("SELECT id FROM users WHERE role = 'admin'");
        while ($admin = $adminUsers->fetch_assoc()) {
            $stmt = $conn->prepare("
                INSERT INTO notifications (user_id, title, content, type, created_at) 
                VALUES (?, ?, ?, 'product_approval', NOW())
            ");
            $title = 'Sản phẩm mới cần duyệt';
            $content = "Sản phẩm '{$product['name']}' từ agency cần được duyệt.";
            $stmt->bind_param("iss", $admin['id'], $title, $content);
            $stmt->execute();
        }
        
        $conn->commit();
        
        sendResponse(true, 'Product submitted for approval successfully', [
            'product_id' => $productId,
            'status' => 'pending'
        ], 200);
    } else {
        $conn->rollback();
        sendResponse(false, 'Failed to submit product for approval', null, 500);
    }
    
} catch (Exception $e) {
    if (isset($conn)) {
        $conn->rollback();
    }
    sendResponse(false, 'Server error: ' . $e->getMessage(), null, 500);
}

$conn->close();
?> 