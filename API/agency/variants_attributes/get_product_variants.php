<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

require_once '../../config/db_connect.php';
require_once '../../utils/auth.php';
require_once '../../utils/response.php';

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

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $productId = $_GET['product_id'] ?? null;
    
    if (!$productId) {
        sendResponse(false, 'Product ID is required', null, 400);
        exit;
    }
    
    // Kiểm tra sản phẩm thuộc về agency này
    $stmt = $conn->prepare("SELECT id FROM products WHERE id = ? AND created_by = ?");
    $stmt->bind_param("ii", $productId, $user['id']);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        sendResponse(false, 'Product not found or access denied', null, 404);
        exit;
    }
    
    try {
        $stmt = $conn->prepare("
            SELECT 
                v.id,
                v.sku,
                pv.price,
                pv.stock,
                pv.image_url,
                pv.status,
                pv.product_id
            FROM variants v
            JOIN product_variant pv ON v.id = pv.variant_id
            WHERE pv.product_id = ?
            ORDER BY v.id
        ");
        $stmt->bind_param("i", $productId);
        $stmt->execute();
        $result = $stmt->get_result();
        
        $variants = [];
        while ($row = $result->fetch_assoc()) {
            // Lấy attributes cho variant này
            $attrStmt = $conn->prepare("
                SELECT 
                    av.id,
                    av.value,
                    av.attribute_id,
                    a.name as attribute_name
                FROM variant_attribute_values vav
                JOIN attribute_values av ON vav.attribute_value_id = av.id
                JOIN attributes a ON av.attribute_id = a.id
                WHERE vav.variant_id = ?
                ORDER BY a.name, av.value
            ");
            $attrStmt->bind_param("i", $row['id']);
            $attrStmt->execute();
            $attrResult = $attrStmt->get_result();
            
            $attributes = [];
            while ($attrRow = $attrResult->fetch_assoc()) {
                $attributes[] = [
                    'id' => $attrRow['id'],
                    'value' => $attrRow['value'],
                    'attribute_id' => $attrRow['attribute_id'],
                    'attribute_name' => $attrRow['attribute_name']
                ];
            }
            
            $variants[] = [
                'id' => $row['id'],
                'sku' => $row['sku'],
                'price' => $row['price'],
                'stock' => $row['stock'],
                'image_url' => $row['image_url'],
                'status' => $row['status'],
                'product_id' => $row['product_id'],
                'attributes' => $attributes
            ];
        }
        
        sendResponse(true, 'Product variants retrieved successfully', $variants);
        
    } catch (Exception $e) {
        sendResponse(false, 'Database error: ' . $e->getMessage(), null, 500);
    }
} else {
    sendResponse(false, 'Method not allowed', null, 405);
}
?> 