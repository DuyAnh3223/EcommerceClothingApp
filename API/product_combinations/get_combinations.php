<?php
// API này trả về danh sách tổ hợp sản phẩm (product combinations) cho FE user hoặc admin.
// Để lấy danh sách tổ hợp đang bán cho khách hàng, gọi:
//   GET /API/product_combinations/get_combinations.php?status=active&page=1&limit=10
// Trả về: id, name, description, image_url, discount_price, original_price, status, created_by, creator_type, created_at, updated_at, categories, items[]
// items[] gồm: product_id, variant_id, quantity, price_in_combination, product_name, product_image, product_category, sku, original_price, stock, variant_image
//
// Nếu muốn lấy chi tiết 1 tổ hợp, FE chỉ cần lấy phần tử trong mảng combinations trả về (không cần API riêng detail).
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Access-Control-Allow-Headers,Content-Type,Access-Control-Allow-Methods,Authorization,X-Requested-With');

include_once '../config/db_connect.php';
include_once '../utils/response.php';
include_once '../utils/auth.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    sendResponse(405, 'Method not allowed');
    exit();
}

try {
    $page = max(1, intval($_GET['page'] ?? 1));
    $limit = max(1, min(50, intval($_GET['limit'] ?? 10)));
    $offset = ($page - 1) * $limit;
    
    $status = $_GET['status'] ?? 'all';
    $creator_type = $_GET['creator_type'] ?? 'all';
    $created_by = $_GET['created_by'] ?? null;
    
    // Build where clause
    $where_conditions = [];
    $params = [];
    $types = "";
    
    if ($status !== 'all') {
        $where_conditions[] = "pc.status = ?";
        $params[] = $status;
        $types .= "s";
    }
    
    if ($creator_type !== 'all') {
        $where_conditions[] = "pc.creator_type = ?";
        $params[] = $creator_type;
        $types .= "s";
    }
    
    if ($created_by !== null) {
        $where_conditions[] = "pc.created_by = ?";
        $params[] = intval($created_by);
        $types .= "i";
    }
    
    $where_clause = !empty($where_conditions) ? "WHERE " . implode(" AND ", $where_conditions) : "";
    
    // Get total count
    $count_query = "
        SELECT COUNT(*) as total 
        FROM product_combinations pc
        $where_clause
    ";
    $stmt = $conn->prepare($count_query);
    if (!empty($params)) {
        $stmt->bind_param($types, ...$params);
    }
    $stmt->execute();
    $total = $stmt->get_result()->fetch_assoc()['total'];
    
    // Get combinations with creator info
    $query = "
        SELECT 
            pc.*,
            u.username as creator_name,
            u.email as creator_email
        FROM product_combinations pc
        LEFT JOIN users u ON pc.created_by = u.id
        $where_clause
        ORDER BY pc.created_at DESC
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
    
    $combinations = [];
    while ($row = $result->fetch_assoc()) {
        // Get categories for this combination
        $cat_query = "SELECT category_name FROM product_combination_categories WHERE combination_id = ?";
        $stmt = $conn->prepare($cat_query);
        $stmt->bind_param("i", $row['id']);
        $stmt->execute();
        $cat_result = $stmt->get_result();
        
        $categories = [];
        while ($cat = $cat_result->fetch_assoc()) {
            $categories[] = $cat['category_name'];
        }
        $row['categories'] = $categories;
        
        // Get items for this combination
        $item_query = "
            SELECT 
                pci.*,
                p.name as product_name,
                p.main_image as product_image,
                p.category as product_category,
                v.sku,
                pv.price as original_price,
                pv.stock,
                pv.image_url as variant_image
            FROM product_combination_items pci
            LEFT JOIN products p ON pci.product_id = p.id
            LEFT JOIN variants v ON pci.variant_id = v.id
            LEFT JOIN product_variant pv ON pci.product_id = pv.product_id AND pci.variant_id = pv.variant_id
            WHERE pci.combination_id = ?
        ";
        $stmt = $conn->prepare($item_query);
        $stmt->bind_param("i", $row['id']);
        $stmt->execute();
        $item_result = $stmt->get_result();
        
        $items = [];
        while ($item = $item_result->fetch_assoc()) {
            $items[] = $item;
        }
        $row['items'] = $items;
        
        $combinations[] = $row;
    }
    
    sendResponse(true, 'Product combinations retrieved successfully', [
        'combinations' => $combinations,
        'total' => $total,
        'page' => $page,
        'limit' => $limit
    ]);
    
} catch (Exception $e) {
    sendResponse(false, 'Error retrieving product combinations: ' . $e->getMessage(), null, 500);
}

$conn->close();
?> 