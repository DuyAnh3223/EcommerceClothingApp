<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../config/db_connect.php';
require_once '../utils/auth.php';
require_once '../utils/response.php';

// Kiểm tra quyền admin
$user = authenticate();
if (!$user || $user['role'] !== 'admin') {
    sendResponse(403, 'Unauthorized', null);
    exit();
}

try {
    $query = "
        SELECT 
            v.id,
            v.voucher_code,
            v.discount_amount,
            v.quantity,
            v.start_date,
            v.end_date,
            v.voucher_type,
            v.category_filter,
            v.created_at,
            v.updated_at,
            GROUP_CONCAT(vpa.product_id) as associated_product_ids
        FROM vouchers v
        LEFT JOIN voucher_product_associations vpa ON v.id = vpa.voucher_id
        GROUP BY v.id
        ORDER BY v.created_at DESC
    ";
    
    $result = mysqli_query($conn, $query);
    
    if (!$result) {
        throw new Exception("Database error: " . mysqli_error($conn));
    }
    
    $vouchers = [];
    while ($row = mysqli_fetch_assoc($result)) {
        // Xử lý associated_product_ids
        $associatedProductIds = null;
        if ($row['associated_product_ids']) {
            $associatedProductIds = array_map('intval', explode(',', $row['associated_product_ids']));
        }
        
        $vouchers[] = [
            'id' => (int)$row['id'],
            'voucher_code' => $row['voucher_code'],
            'discount_amount' => (float)$row['discount_amount'],
            'quantity' => (int)$row['quantity'],
            'start_date' => $row['start_date'],
            'end_date' => $row['end_date'],
            'voucher_type' => $row['voucher_type'] ?? 'all_products',
            'category_filter' => $row['category_filter'],
            'associated_product_ids' => $associatedProductIds,
            'created_at' => $row['created_at'],
            'updated_at' => $row['updated_at']
        ];
    }
    
    sendResponse(200, 'Vouchers retrieved successfully', $vouchers);
    
} catch (Exception $e) {
    sendResponse(500, 'Error: ' . $e->getMessage(), null);
}

mysqli_close($conn);
?> 