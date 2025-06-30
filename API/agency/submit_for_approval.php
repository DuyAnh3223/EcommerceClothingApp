<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

require_once '../config/db_connect.php';
require_once '../utils/response.php';

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
    
    // Check if product is in draft or rejected status
    if (!in_array($product['status'], ['draft', 'rejected'])) {
        sendResponse(false, 'Product can only be submitted when in draft or rejected status', null, 400);
    }
    
    // Check if product has variants
    $stmt = $conn->prepare("
        SELECT COUNT(*) as variant_count 
        FROM product_variant 
        WHERE product_id = ?
    ");
    $stmt->bind_param("i", $productId);
    $stmt->execute();
    $variantResult = $stmt->get_result();
    $variantCount = $variantResult->fetch_assoc()['variant_count'];
    
    if ($variantCount === 0) {
        sendResponse(false, 'Product must have at least one variant before submission', null, 400);
    }
    
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
        
        sendResponse(true, 'Product submitted for approval successfully', [
            'product_id' => $productId,
            'status' => 'pending'
        ], 200);
    } else {
        sendResponse(false, 'Failed to submit product for approval', null, 500);
    }
    
} catch (Exception $e) {
    sendResponse(false, 'Server error: ' . $e->getMessage(), null, 500);
}

$conn->close();
?> 