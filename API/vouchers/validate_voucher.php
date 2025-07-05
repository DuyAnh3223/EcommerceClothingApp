<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once '../config/db_connect.php';
require_once '../utils/auth.php';
require_once '../utils/response.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(false, 'Method not allowed', null, 405);
    exit;
}

try {
    $input = json_decode(file_get_contents('php://input'), true);
    
    // Validate input
    if (!isset($input['voucher_code']) || empty($input['voucher_code'])) {
        sendResponse(false, 'Voucher code is required', null, 400);
        exit;
    }
    
    if (!isset($input['product_ids']) || !is_array($input['product_ids'])) {
        sendResponse(false, 'Product IDs array is required', null, 400);
        exit;
    }
    
    $voucherCode = mysqli_real_escape_string($conn, $input['voucher_code']);
    $productIds = array_map('intval', $input['product_ids']);
    $productIdsStr = implode(',', $productIds);
    
    // Get voucher details
    $voucherQuery = "
        SELECT 
            v.id,
            v.voucher_code,
            v.discount_amount,
            v.quantity,
            v.start_date,
            v.end_date,
            v.voucher_type,
            v.category_filter,
            COUNT(vu.id) as used_count
        FROM vouchers v
        LEFT JOIN voucher_usage vu ON v.id = vu.voucher_id
        WHERE v.voucher_code = '$voucherCode'
        GROUP BY v.id
    ";
    
    $voucherResult = mysqli_query($conn, $voucherQuery);
    
    if (!$voucherResult || mysqli_num_rows($voucherResult) === 0) {
        sendResponse(false, 'Voucher not found', null, 404);
        exit;
    }
    
    $voucher = mysqli_fetch_assoc($voucherResult);
    
    // Check if voucher is valid
    $now = new DateTime();
    $startDate = new DateTime($voucher['start_date']);
    $endDate = new DateTime($voucher['end_date']);
    
    if ($now < $startDate || $now > $endDate) {
        sendResponse(false, 'Voucher is not valid at this time', null, 400);
        exit;
    }
    
    // Check if voucher has remaining quantity
    $remainingQuantity = $voucher['quantity'] - $voucher['used_count'];
    if ($remainingQuantity <= 0) {
        sendResponse(false, 'Voucher has been fully used', null, 400);
        exit;
    }
    
    // Check voucher type and product applicability
    $applicableProducts = [];
    $totalDiscount = 0;
    
    switch ($voucher['voucher_type']) {
        case 'all_products':
            // Voucher applies to all products
            $applicableProducts = $productIds;
            $totalDiscount = $voucher['discount_amount'] * count($productIds);
            break;
            
        case 'specific_products':
            // Check which products are associated with this voucher
            $assocQuery = "
                SELECT product_id 
                FROM voucher_product_associations 
                WHERE voucher_id = {$voucher['id']} 
                AND product_id IN ($productIdsStr)
            ";
            $assocResult = mysqli_query($conn, $assocQuery);
            
            while ($row = mysqli_fetch_assoc($assocResult)) {
                $applicableProducts[] = $row['product_id'];
            }
            
            if (!empty($applicableProducts)) {
                $totalDiscount = $voucher['discount_amount'] * count($applicableProducts);
            }
            break;
            
        case 'category_based':
            // Check which products belong to the specified category
            $categoryFilter = mysqli_real_escape_string($conn, $voucher['category_filter']);
            $categoryQuery = "
                SELECT id 
                FROM products 
                WHERE id IN ($productIdsStr) 
                AND category = '$categoryFilter'
            ";
            $categoryResult = mysqli_query($conn, $categoryQuery);
            
            while ($row = mysqli_fetch_assoc($categoryResult)) {
                $applicableProducts[] = $row['id'];
            }
            
            if (!empty($applicableProducts)) {
                $totalDiscount = $voucher['discount_amount'] * count($applicableProducts);
            }
            break;
            
        default:
            sendResponse(false, 'Invalid voucher type', null, 400);
            exit;
    }
    
    if (empty($applicableProducts)) {
        sendResponse(false, 'Voucher is not applicable to any of the selected products', null, 400);
        exit;
    }
    
    // Return validation result
    $result = [
        'voucher_id' => (int)$voucher['id'],
        'voucher_code' => $voucher['voucher_code'],
        'discount_amount' => (float)$voucher['discount_amount'],
        'total_discount' => $totalDiscount,
        'applicable_products' => $applicableProducts,
        'remaining_quantity' => $remainingQuantity,
        'voucher_type' => $voucher['voucher_type'],
        'category_filter' => $voucher['category_filter']
    ];
    
    sendResponse(true, 'Voucher is valid', $result);
    
} catch (Exception $e) {
    sendResponse(false, 'Error: ' . $e->getMessage(), null, 500);
}

mysqli_close($conn);
?> 