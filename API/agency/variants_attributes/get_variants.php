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

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    sendResponse(false, 'Method not allowed', null, 405);
    exit();
}

try {
    $product_id = isset($_GET['product_id']) ? intval($_GET['product_id']) : null;
    
    // Build query based on product_id filter
    $where_clause = "WHERE p.created_by = ? AND p.is_agency_product = 1";
    $params = [$user['id']];
    $types = "i";
    
    if ($product_id) {
        $where_clause .= " AND p.id = ?";
        $params[] = $product_id;
        $types .= "i";
    }
    
    // Get variants with product info
    $query = "
        SELECT 
            v.id as variant_id,
            v.sku,
            pv.price,
            pv.stock,
            pv.image_url,
            pv.status as variant_status,
            p.id as product_id,
            p.name as product_name,
            p.status as product_status
        FROM product_variant pv
        JOIN variants v ON pv.variant_id = v.id
        JOIN products p ON pv.product_id = p.id
        $where_clause
        ORDER BY p.name ASC, v.sku ASC
    ";
    
    $stmt = $conn->prepare($query);
    $stmt->bind_param($types, ...$params);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $variants = [];
    while ($row = $result->fetch_assoc()) {
        // Get attributes for this variant
        $attr_query = "
            SELECT 
                a.id as attribute_id,
                a.name as attribute_name,
                av.id as value_id,
                av.value as attribute_value
            FROM variant_attribute_values vav
            JOIN attribute_values av ON vav.attribute_value_id = av.id
            JOIN attributes a ON av.attribute_id = a.id
            WHERE vav.variant_id = ?
            ORDER BY a.name ASC
        ";
        
        $stmt = $conn->prepare($attr_query);
        $stmt->bind_param("i", $row['variant_id']);
        $stmt->execute();
        $attrs_result = $stmt->get_result();
        
        $attributes = [];
        while ($attr = $attrs_result->fetch_assoc()) {
            $attributes[] = [
                'attribute_id' => $attr['attribute_id'],
                'attribute_name' => $attr['attribute_name'],
                'value_id' => $attr['value_id'],
                'value' => $attr['attribute_value']
            ];
        }
        
        $variants[] = [
            'variant_id' => $row['variant_id'],
            'sku' => $row['sku'],
            'price' => floatval($row['price']),
            'stock' => intval($row['stock']),
            'image_url' => $row['image_url'],
            'variant_status' => $row['variant_status'],
            'product_id' => $row['product_id'],
            'product_name' => $row['product_name'],
            'product_status' => $row['product_status'],
            'attributes' => $attributes
        ];
    }
    
    sendResponse(true, 'Variants retrieved successfully', [
        'variants' => $variants,
        'total' => count($variants)
    ], 200);
    
} catch (Exception $e) {
    sendResponse(false, 'Error retrieving variants: ' . $e->getMessage(), null, 500);
}

$conn->close();
?> 