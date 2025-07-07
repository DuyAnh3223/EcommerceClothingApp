<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

require_once '../config/db_connect.php';
require_once '../utils/response.php';

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

try {
    // Lấy thông tin giỏ hàng từ request
    $input = json_decode(file_get_contents('php://input'), true);
    $user_id = $input['user_id'] ?? null;
    $cart_total = $input['cart_total'] ?? 0;
    $cart_quantity = $input['cart_quantity'] ?? 0;
    
    if (!$user_id) {
        sendResponse(false, 'User ID is required', null, 400);
        exit;
    }
    
    // Lấy tất cả voucher có hiệu lực
    $sql = "SELECT 
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
                v.min_total_amount,
                v.created_at
            FROM vouchers v
            WHERE v.status = 'active' 
            AND v.quantity > 0
            AND v.start_date <= NOW()
            AND v.end_date >= NOW()
            ORDER BY v.discount_amount DESC";
    
    $result = $conn->query($sql);
    
    if (!$result) {
        throw new Exception("Database query failed: " . $conn->error);
    }
    
    $vouchers = [];
    while ($row = $result->fetch_assoc()) {
        $vouchers[] = $row;
    }
    
    $available_vouchers = [];
    
    foreach ($vouchers as $voucher) {
        // Kiểm tra điều kiện số lượng và tổng tiền
        $meets_quantity = $cart_quantity >= $voucher['min_quantity'];
        $meets_amount = $cart_total >= $voucher['min_total_amount'];
        
        // Kiểm tra xem user đã sử dụng voucher này chưa
        $usage_sql = "SELECT COUNT(*) as used_count FROM voucher_usage 
                      WHERE voucher_id = ? AND user_id = ?";
        $usage_stmt = $conn->prepare($usage_sql);
        $usage_stmt->bind_param("ii", $voucher['id'], $user_id);
        $usage_stmt->execute();
        $usage_result = $usage_stmt->get_result();
        $usage_row = $usage_result->fetch_assoc();
        $already_used = $usage_row['used_count'] > 0;
        $usage_stmt->close();
        
        // Tạo thông báo điều kiện
        $conditions = [];
        if ($voucher['min_quantity'] > 1) {
            $conditions[] = "Số lượng ≥ " . $voucher['min_quantity'];
        }
        if ($voucher['min_total_amount'] > 0) {
            $conditions[] = "Tổng tiền ≥ " . number_format($voucher['min_total_amount']) . "đ";
        }
        
        $condition_text = !empty($conditions) ? " (" . implode(" và ", $conditions) . ")" : "";
        
        $voucher_data = [
            'id' => (int)$voucher['id'],
            'voucher_code' => $voucher['voucher_code'],
            'discount_amount' => (float)$voucher['discount_amount'],
            'discount_formatted' => number_format($voucher['discount_amount']) . "đ",
            'min_quantity' => (int)$voucher['min_quantity'],
            'min_total_amount' => (float)$voucher['min_total_amount'],
            'condition_text' => $condition_text,
            'is_available' => $meets_quantity && $meets_amount && !$already_used,
            'meets_quantity' => $meets_quantity,
            'meets_amount' => $meets_amount,
            'already_used' => $already_used,
            'status_message' => ''
        ];
        
        // Tạo thông báo trạng thái
        if ($already_used) {
            $voucher_data['status_message'] = "Đã sử dụng voucher này";
        } elseif (!$meets_quantity && !$meets_amount) {
            $voucher_data['status_message'] = "Chưa đủ điều kiện" . $condition_text;
        } elseif (!$meets_quantity) {
            $voucher_data['status_message'] = "Cần " . $voucher['min_quantity'] . " sản phẩm trở lên";
        } elseif (!$meets_amount) {
            $voucher_data['status_message'] = "Cần tổng tiền ≥ " . number_format($voucher['min_total_amount']) . "đ";
        } else {
            $voucher_data['status_message'] = "Có thể sử dụng";
        }
        
        $available_vouchers[] = $voucher_data;
    }
    
    // Phân loại voucher
    $eligible_vouchers = array_filter($available_vouchers, function($v) {
        return $v['is_available'];
    });
    
    $ineligible_vouchers = array_filter($available_vouchers, function($v) {
        return !$v['is_available'];
    });
    
    $response = [
        'eligible_vouchers' => array_values($eligible_vouchers),
        'ineligible_vouchers' => array_values($ineligible_vouchers),
        'cart_info' => [
            'total_amount' => (float)$cart_total,
            'total_quantity' => (int)$cart_quantity
        ]
    ];
    
    sendResponse(true, 'Lấy danh sách voucher thành công', $response);
    
} catch (Exception $e) {
    sendResponse(false, 'Server error: ' . $e->getMessage(), null, 500);
}
?> 