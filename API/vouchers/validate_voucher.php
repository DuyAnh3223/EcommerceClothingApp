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

// Set timezone to Vietnam
date_default_timezone_set('Asia/Ho_Chi_Minh');

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
        sendResponse(false, 'Mã voucher không được để trống', null, 400);
        exit;
    }
    
    if (!isset($input['product_ids']) || !is_array($input['product_ids'])) {
        sendResponse(false, 'Danh sách sản phẩm không hợp lệ', null, 400);
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
            v.status,
            v.min_quantity,
            v.min_total_amount
        FROM vouchers v
        WHERE v.voucher_code = '$voucherCode'
    ";
    
    $voucherResult = mysqli_query($conn, $voucherQuery);
    
    if (!$voucherResult || mysqli_num_rows($voucherResult) === 0) {
        sendResponse(false, 'Mã voucher không tồn tại', null, 404);
        exit;
    }
    
    $voucher = mysqli_fetch_assoc($voucherResult);
    
    // Check if voucher is valid
    $now = new DateTime('now', new DateTimeZone('Asia/Ho_Chi_Minh'));
    $startDate = new DateTime($voucher['start_date'], new DateTimeZone('Asia/Ho_Chi_Minh'));
    $endDate = new DateTime($voucher['end_date'], new DateTimeZone('Asia/Ho_Chi_Minh'));
    
    // Debug logging
    error_log("Voucher validation debug:");
    error_log("Current time: " . $now->format('Y-m-d H:i:s'));
    error_log("Start date: " . $startDate->format('Y-m-d H:i:s'));
    error_log("End date: " . $endDate->format('Y-m-d H:i:s'));
    error_log("Is current time before start date: " . ($now < $startDate ? 'YES' : 'NO'));
    error_log("Is current time after end date: " . ($now > $endDate ? 'YES' : 'NO'));
    error_log("Voucher status: " . $voucher['status']);
    error_log("Voucher quantity: " . $voucher['quantity']);
    
    // Check voucher validity period
    if ($now < $startDate) {
        $startDateFormatted = $startDate->format('d/m/Y H:i');
        sendResponse(false, "Voucher chưa có hiệu lực. Thời gian bắt đầu: $startDateFormatted", null, 400);
        exit;
    }
    
    if ($now > $endDate) {
        $endDateFormatted = $endDate->format('d/m/Y H:i');
        sendResponse(false, "Voucher đã hết hiệu lực. Thời gian kết thúc: $endDateFormatted", null, 400);
        exit;
    }
    
    // Check voucher status and quantity using new logic
    if ($voucher['status'] !== 'active') {
        if ($voucher['status'] === 'inactive') {
            sendResponse(false, 'Voucher đã hết số lượng sử dụng', null, 400);
        } elseif ($voucher['status'] === 'expired') {
            sendResponse(false, 'Voucher đã hết hiệu lực', null, 400);
        } else {
            sendResponse(false, 'Voucher không hợp lệ', null, 400);
        }
        exit;
    }
    
    if ($voucher['quantity'] <= 0) {
        sendResponse(false, 'Voucher đã hết số lượng sử dụng', null, 400);
        exit;
    }
    
    // Lấy thêm min_quantity, min_total_amount
    $minQuantity = isset($voucher['min_quantity']) ? (int)$voucher['min_quantity'] : 1;
    $minTotalAmount = isset($voucher['min_total_amount']) ? (float)$voucher['min_total_amount'] : 0.0;
    $totalQuantity = 0;
    $totalAmount = 0;
    if (isset($input['quantities']) && is_array($input['quantities'])) {
        $totalQuantity = array_sum($input['quantities']);
    }
    if (isset($input['prices']) && is_array($input['prices'])) {
        $totalAmount = array_sum($input['prices']);
    }
    if ($totalQuantity < $minQuantity) {
        sendResponse(false, "Cần mua tối thiểu $minQuantity sản phẩm để áp dụng voucher", null, 400);
        exit;
    }
    if ($totalAmount < $minTotalAmount) {
        sendResponse(false, "Cần tổng tiền tối thiểu " . number_format($minTotalAmount) . "đ để áp dụng voucher", null, 400);
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
            sendResponse(false, 'Loại voucher không hợp lệ', null, 400);
            exit;
    }
    
    if (empty($applicableProducts)) {
        sendResponse(false, 'Voucher không áp dụng được cho sản phẩm đã chọn', null, 400);
        exit;
    }
    
    // Return validation result
    $result = [
        'voucher_id' => (int)$voucher['id'],
        'voucher_code' => $voucher['voucher_code'],
        'discount_amount' => (float)$voucher['discount_amount'],
        'total_discount' => $totalDiscount,
        'applicable_products' => $applicableProducts,
        'remaining_quantity' => (int)$voucher['quantity'],
        'voucher_type' => $voucher['voucher_type'],
        'category_filter' => $voucher['category_filter']
    ];
    
    sendResponse(true, 'Voucher hợp lệ', $result);
    
} catch (Exception $e) {
    sendResponse(false, 'Lỗi hệ thống: ' . $e->getMessage(), null, 500);
}

mysqli_close($conn);
?> 