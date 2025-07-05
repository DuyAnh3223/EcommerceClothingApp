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
require_once '../utils/validate.php';

// Kiểm tra quyền admin
$user = authenticate();
if (!$user || $user['role'] !== 'admin') {
    sendResponse(403, 'Unauthorized', null);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(405, 'Method not allowed', null);
    exit();
}

try {
    $input = json_decode(file_get_contents('php://input'), true);
    
    // Validate input
    $requiredFields = ['voucher_code', 'discount_amount', 'quantity', 'start_date', 'end_date'];
    foreach ($requiredFields as $field) {
        if (!isset($input[$field]) || empty($input[$field])) {
            sendResponse(400, "Missing required field: $field", null);
            exit();
        }
    }
    
    $voucherCode = mysqli_real_escape_string($conn, $input['voucher_code']);
    $discountAmount = floatval($input['discount_amount']);
    $quantity = intval($input['quantity']);
    $startDate = mysqli_real_escape_string($conn, $input['start_date']);
    $endDate = mysqli_real_escape_string($conn, $input['end_date']);
    $voucherType = mysqli_real_escape_string($conn, $input['voucher_type'] ?? 'all_products');
    $categoryFilter = isset($input['category_filter']) ? mysqli_real_escape_string($conn, $input['category_filter']) : null;
    $associatedProductIds = isset($input['associated_product_ids']) ? $input['associated_product_ids'] : [];
    
    // Validate voucher code uniqueness
    $checkQuery = "SELECT id FROM vouchers WHERE voucher_code = '$voucherCode'";
    $checkResult = mysqli_query($conn, $checkQuery);
    if (mysqli_num_rows($checkResult) > 0) {
        sendResponse(400, 'Voucher code already exists', null);
        exit();
    }
    
    // Validate dates
    $startDateTime = new DateTime($startDate);
    $endDateTime = new DateTime($endDate);
    if ($startDateTime >= $endDateTime) {
        sendResponse(400, 'End date must be after start date', null);
        exit();
    }
    
    // Validate voucher type
    $validTypes = ['all_products', 'specific_products', 'category_based'];
    if (!in_array($voucherType, $validTypes)) {
        sendResponse(400, 'Invalid voucher type', null);
        exit();
    }
    
    // Validate associated products if voucher type is specific_products
    if ($voucherType === 'specific_products' && empty($associatedProductIds)) {
        sendResponse(400, 'Associated products are required for specific products voucher type', null);
        exit();
    }
    
    // Validate category filter if voucher type is category_based
    if ($voucherType === 'category_based' && empty($categoryFilter)) {
        sendResponse(400, 'Category filter is required for category-based voucher type', null);
        exit();
    }
    
    // Begin transaction
    mysqli_begin_transaction($conn);
    
    try {
        // Insert voucher
        $query = "
            INSERT INTO vouchers (voucher_code, discount_amount, quantity, start_date, end_date, voucher_type, category_filter)
            VALUES ('$voucherCode', $discountAmount, $quantity, '$startDate', '$endDate', '$voucherType', " . 
            ($categoryFilter ? "'$categoryFilter'" : "NULL") . ")
        ";
        
        if (!mysqli_query($conn, $query)) {
            throw new Exception("Error inserting voucher: " . mysqli_error($conn));
        }
        
        $voucherId = mysqli_insert_id($conn);
        
        // Insert associated products if voucher type is specific_products
        if ($voucherType === 'specific_products' && !empty($associatedProductIds)) {
            foreach ($associatedProductIds as $productId) {
                $productId = intval($productId);
                $assocQuery = "INSERT INTO voucher_product_associations (voucher_id, product_id) VALUES ($voucherId, $productId)";
                if (!mysqli_query($conn, $assocQuery)) {
                    throw new Exception("Error inserting product association: " . mysqli_error($conn));
                }
            }
        }
        
        mysqli_commit($conn);
        
        // Return the created voucher
        $voucher = [
            'id' => $voucherId,
            'voucher_code' => $voucherCode,
            'discount_amount' => $discountAmount,
            'quantity' => $quantity,
            'start_date' => $startDate,
            'end_date' => $endDate,
            'voucher_type' => $voucherType,
            'category_filter' => $categoryFilter,
            'associated_product_ids' => $associatedProductIds
        ];
        
        sendResponse(201, 'Voucher created successfully', $voucher);
        
    } catch (Exception $e) {
        mysqli_rollback($conn);
        throw $e;
    }
    
} catch (Exception $e) {
    sendResponse(500, 'Error: ' . $e->getMessage(), null);
}

mysqli_close($conn);
?> 