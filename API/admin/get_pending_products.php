<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Access-Control-Allow-Headers,Content-Type,Access-Control-Allow-Methods,Authorization,X-Requested-With');

include_once '../config/db_connect.php';
include_once '../utils/response.php';
include_once '../utils/auth.php';

// Check if user is admin
$user = authenticate();
if (!$user || $user['role'] !== 'admin') {
    sendResponse(403, 'Access denied. Admin role required.');
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    sendResponse(405, 'Method not allowed');
    exit();
}

try {
    $status = $_GET['status'] ?? 'pending';
    $page = max(1, intval($_GET['page'] ?? 1));
    $limit = max(1, min(50, intval($_GET['limit'] ?? 10)));
    $offset = ($page - 1) * $limit;
    
    // Build query based on status filter
    $where_clause = "WHERE p.is_agency_product = 1";
    $params = [];
    $types = "";
    
    if ($status !== 'all') {
        $where_clause .= " AND p.status = ?";
        $params[] = $status;
        $types .= "s";
    }
    
    // Get total count
    $count_query = "SELECT COUNT(*) as total FROM products p $where_clause";
    $stmt = $conn->prepare($count_query);
    if (!empty($params)) {
        $stmt->bind_param($types, ...$params);
    }
    $stmt->execute();
    $total = $stmt->get_result()->fetch_assoc()['total'];
    
    // Get products with agency info
    $query = "
        SELECT 
            p.*,
            pa.status as approval_status,
            pa.review_notes,
            pa.reviewed_at,
            u.username as agency_name,
            u.email as agency_email,
            u.phone as agency_phone
        FROM products p
        LEFT JOIN product_approvals pa ON p.id = pa.product_id
        LEFT JOIN users u ON p.created_by = u.id
        $where_clause
        ORDER BY p.created_at DESC
        LIMIT ? OFFSET ?
    ";
    
    $params[] = $limit;
    $params[] = $offset;
    $types .= "ii";
    
    $stmt = $conn->prepare($query);
    if (!empty($params)) {
        $stmt->bind_param($types, ...$params);
    }
    $stmt->execute();
    $result = $stmt->get_result();
    
    $products = [];
    while ($row = $result->fetch_assoc()) {
        // Get variants for this product
        $variant_query = "
            SELECT 
                v.id as variant_id,
                v.sku,
                pv.price,
                pv.stock,
                pv.image_url,
                pv.status as variant_status
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
                    a.name as attribute_name,
                    av.value as attribute_value,
                    a.created_by as attr_created_by,
                    av.created_by as value_created_by
                FROM variant_attribute_values vav
                JOIN attribute_values av ON vav.attribute_value_id = av.id
                JOIN attributes a ON av.attribute_id = a.id
                WHERE vav.variant_id = ?
            ";
            $stmt = $conn->prepare($attr_query);
            $stmt->bind_param("i", $variant['variant_id']);
            $stmt->execute();
            $attrs_result = $stmt->get_result();
            
            $attributes = [];
            while ($attr = $attrs_result->fetch_assoc()) {
                $attributes[$attr['attribute_name']] = [
                    'value' => $attr['attribute_value'],
                    'attr_created_by' => $attr['attr_created_by'],
                    'value_created_by' => $attr['value_created_by']
                ];
            }
            
            $variant['attributes'] = $attributes;
            $variants[] = $variant;
        }
        
        $row['variants'] = $variants;
        $products[] = $row;
    }
    
    sendResponse(200, 'Products retrieved successfully', [
        'products' => $products,
        'pagination' => [
            'current_page' => $page,
            'total_pages' => ceil($total / $limit),
            'total_items' => $total,
            'items_per_page' => $limit
        ]
    ]);
    
} catch (Exception $e) {
    sendResponse(500, 'Error retrieving products: ' . $e->getMessage());
}

$conn->close();
?> 