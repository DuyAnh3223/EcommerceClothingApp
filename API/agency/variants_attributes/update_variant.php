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

require_once '../../config/db_connect.php';
require_once '../../utils/response.php';
require_once '../../utils/auth.php';

// Kiểm tra authentication
$user = authenticate();
if (!$user) {
    sendResponse(false, 'Unauthorized', null, 401);
    exit;
}

// Kiểm tra role agency
if ($user['role'] !== 'agency') {
    sendResponse(false, 'Access denied. Agency role required.', null, 403);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'PUT') {
    $input = json_decode(file_get_contents('php://input'), true);
    
    $variantId = $input['variant_id'] ?? null;
    $sku = $input['sku'] ?? null;
    $price = $input['price'] ?? null;
    $stock = $input['stock'] ?? null;
    $attributeValueIds = $input['attribute_value_ids'] ?? [];
    
    if (!$variantId || !$sku || $price === null || $stock === null) {
        sendResponse(false, 'Missing required fields', null, 400);
        exit;
    }
    
    // Kiểm tra variant thuộc về sản phẩm của agency này
    $stmt = $conn->prepare("
        SELECT pv.variant_id 
        FROM product_variant pv
        JOIN products p ON pv.product_id = p.id
        WHERE pv.variant_id = ? AND p.created_by = ?
    ");
    $stmt->bind_param("ii", $variantId, $user['id']);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        sendResponse(false, 'Variant not found or access denied', null, 404);
        exit;
    }
    
    try {
        $conn->begin_transaction();
        
        // Cập nhật SKU
        $stmt = $conn->prepare("UPDATE variants SET sku = ? WHERE id = ?");
        $stmt->bind_param("si", $sku, $variantId);
        $stmt->execute();
        
        // Cập nhật thông tin variant
        $stmt = $conn->prepare("UPDATE product_variant SET price = ?, stock = ? WHERE variant_id = ?");
        $stmt->bind_param("dii", $price, $stock, $variantId);
        $stmt->execute();
        
        // Xóa attributes cũ
        $stmt = $conn->prepare("DELETE FROM variant_attribute_values WHERE variant_id = ?");
        $stmt->bind_param("i", $variantId);
        $stmt->execute();
        
        // Thêm attributes mới
        if (!empty($attributeValueIds)) {
            $stmt = $conn->prepare("INSERT INTO variant_attribute_values (variant_id, attribute_value_id) VALUES (?, ?)");
            foreach ($attributeValueIds as $attrValueId) {
                $stmt->bind_param("ii", $variantId, $attrValueId);
                $stmt->execute();
            }
        }
        
        $conn->commit();
        sendResponse(true, 'Variant updated successfully');
        
    } catch (Exception $e) {
        $conn->rollback();
        sendResponse(false, 'Database error: ' . $e->getMessage(), null, 500);
    }
} else {
    sendResponse(false, 'Method not allowed', null, 405);
}
?> 