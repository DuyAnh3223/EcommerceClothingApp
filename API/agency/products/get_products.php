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
    $status = $_GET['status'] ?? 'all';
    $page = max(1, intval($_GET['page'] ?? 1));
    $limit = max(1, min(50, intval($_GET['limit'] ?? 10)));
    $offset = ($page - 1) * $limit;
    
    // Build query based on status filter
    $where_clause = "WHERE p.created_by = ? AND p.is_agency_product = 1";
    $params = [$user['id']];
    $types = "i";
    
    if ($status !== 'all') {
        $where_clause .= " AND p.status = ?";
        $params[] = $status;
        $types .= "s";
    }
    
    // Get total count
    $count_query = "SELECT COUNT(*) as total FROM products p $where_clause";
    $stmt = $conn->prepare($count_query);
    $stmt->bind_param($types, ...$params);
    $stmt->execute();
    $total = $stmt->get_result()->fetch_assoc()['total'];
    
    // Get products with approval info (latest approval record only)
    $query = "
        SELECT 
            p.*,
            pa.status as approval_status,
            pa.review_notes,
            pa.reviewed_at,
            reviewer.username as reviewer_name
        FROM products p
        LEFT JOIN (
            SELECT pa1.*
            FROM product_approvals pa1
            INNER JOIN (
                SELECT product_id, MAX(created_at) as max_created_at
                FROM product_approvals
                GROUP BY product_id
            ) pa2 ON pa1.product_id = pa2.product_id AND pa1.created_at = pa2.max_created_at
        ) pa ON p.id = pa.product_id
        LEFT JOIN users reviewer ON pa.reviewed_by = reviewer.id
        $where_clause
        ORDER BY p.created_at DESC
        LIMIT ? OFFSET ?
    ";
    
    $params[] = $limit;
    $params[] = $offset;
    $types .= "ii";
    
    $stmt = $conn->prepare($query);
    $stmt->bind_param($types, ...$params);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $products = [];
    $seen_products = []; // Track seen product IDs to avoid duplicates
    
    while ($row = $result->fetch_assoc()) {
        // Skip if we've already processed this product
        if (in_array($row['id'], $seen_products)) {
            continue;
        }
        
        $seen_products[] = $row['id'];
        
        // Get variants for this product
        $variant_query = "
            SELECT 
                v.id,
                v.sku,
                pv.price,
                pv.stock,
                pv.image_url,
                pv.status,
                pv.product_id
            FROM product_variant pv
            JOIN variants v ON pv.variant_id = v.id
            WHERE pv.product_id = ?
        ";
        $stmt = $conn->prepare($variant_query);
        $stmt->bind_param("i", $row['id']);
        $stmt->execute();
        $variants_result = $stmt->get_result();
        
        $variants = [];
        while ($variant = $variants_result->fetch_assoc()) {
            // Get attributes for this variant
            $attr_query = "
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
            ";
            $stmt = $conn->prepare($attr_query);
            $stmt->bind_param("i", $variant['id']);
            $stmt->execute();
            $attrs_result = $stmt->get_result();
            
            $attributes = [];
            while ($attr = $attrs_result->fetch_assoc()) {
                $attributes[] = [
                    'id' => $attr['id'],
                    'value' => $attr['value'],
                    'attribute_id' => $attr['attribute_id'],
                    'attribute_name' => $attr['attribute_name']
                ];
            }
            
            $variant['attributes'] = $attributes;
            $variants[] = $variant;
        }
        
        $row['variants'] = $variants;
        $products[] = $row;
    }
    
    sendResponse(true, 'Products retrieved successfully', [
        'products' => $products,
        'total' => $total,
        'page' => $page,
        'limit' => $limit
    ], 200);
    
} catch (Exception $e) {
    sendResponse(false, 'Error retrieving products: ' . $e->getMessage(), null, 500);
}

$conn->close();
?>