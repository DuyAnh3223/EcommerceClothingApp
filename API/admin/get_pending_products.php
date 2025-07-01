<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Access-Control-Allow-Headers,Content-Type,Access-Control-Allow-Methods,Authorization,X-Requested-With');

include_once '../config/db_connect.php';
include_once '../utils/response.php';
include_once '../utils/auth.php';

// Check if user is admin
// $user = authenticate();
// if (!$user || $user['role'] !== 'admin') {
//     sendResponse(403, 'Access denied. Admin role required.');
//     exit();
// }

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
    
    if ($status === 'approved') {
        // For approved products, get from product_approvals table
        $where_clause = "WHERE p.is_agency_product = 1 AND pa.status = 'approved'";
    } elseif ($status === 'rejected') {
        // For rejected products, get from product_approvals table
        $where_clause = "WHERE p.is_agency_product = 1 AND pa.status = 'rejected'";
    } elseif ($status === 'pending') {
        // For pending products, get products that are pending or have no approval record
        $where_clause = "WHERE p.is_agency_product = 1 AND (p.status = 'pending' OR pa.status IS NULL OR pa.status = 'pending')";
    } else {
        // For 'all' status, no additional filter
        $where_clause = "WHERE p.is_agency_product = 1";
    }
    
    // Get total count
    $count_query = "
        SELECT COUNT(DISTINCT p.id) as total 
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
        $where_clause
    ";
    $stmt = $conn->prepare($count_query);
    $stmt->execute();
    $total = $stmt->get_result()->fetch_assoc()['total'];
    
    // Get products with agency info (latest approval record only)
    $query = "
        SELECT 
            p.*,
            pa.status as approval_status,
            pa.review_notes,
            pa.reviewed_at,
            u.username as agency_name,
            u.email as agency_email,
            u.phone as agency_phone,
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
        LEFT JOIN users u ON p.created_by = u.id
        LEFT JOIN users reviewer ON pa.reviewed_by = reviewer.id
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
    
    sendResponse(true, 'Products retrieved successfully', [
        'products' => $products,
        'total' => $total,
        'page' => $page,
        'limit' => $limit
    ]);
    
} catch (Exception $e) {
    sendResponse(false, 'Error retrieving products: ' . $e->getMessage(), null, 500);
}

$conn->close();
?> 