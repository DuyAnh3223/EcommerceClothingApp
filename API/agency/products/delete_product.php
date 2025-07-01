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

if ($_SERVER['REQUEST_METHOD'] !== 'DELETE') {
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
    
    // Check if product can be deleted (not in pending or approved status)
    if (in_array($product['status'], ['pending', 'approved'])) {
        sendResponse(false, 'Cannot delete product in pending or approved status', null, 400);
        exit();
    }
    
    $conn->begin_transaction();
    
    // Delete product variants first
    $stmt = $conn->prepare("
        DELETE pv FROM product_variant pv
        JOIN variants v ON pv.variant_id = v.id
        WHERE pv.product_id = ?
    ");
    $stmt->bind_param("i", $product_id);
    $stmt->execute();
    
    // Delete product approval record
    $stmt = $conn->prepare("DELETE FROM product_approvals WHERE product_id = ?");
    $stmt->bind_param("i", $product_id);
    $stmt->execute();
    
    // Delete the product
    $stmt = $conn->prepare("DELETE FROM products WHERE id = ?");
    $stmt->bind_param("i", $product_id);
    
    if ($stmt->execute()) {
        $conn->commit();
        sendResponse(true, 'Product deleted successfully', [
            'product_id' => $product_id
        ], 200);
    } else {
        $conn->rollback();
        sendResponse(false, 'Failed to delete product', null, 500);
    }
    
} catch (Exception $e) {
    if (isset($conn)) {
        $conn->rollback();
    }
    sendResponse(false, 'Server error: ' . $e->getMessage(), null, 500);
}

$conn->close();
?> 