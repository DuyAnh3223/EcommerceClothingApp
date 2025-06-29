<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    exit(0);
}

error_reporting(E_ALL & ~E_NOTICE & ~E_DEPRECATED);
date_default_timezone_set('Asia/Ho_Chi_Minh');

require_once("./config.php");

// Kiểm tra method
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
    exit;
}

// Lấy dữ liệu từ request
$input = json_decode(file_get_contents('php://input'), true);

// Handle test action
if (isset($input['action']) && $input['action'] === 'test') {
    echo json_encode([
        'success' => true,
        'message' => 'API connection test successful',
        'timestamp' => date('Y-m-d H:i:s'),
        'timezone' => date_default_timezone_get(),
        'vnpay_config' => [
            'tmn_code' => $vnp_TmnCode,
            'return_url' => $vnp_Returnurl,
            'url' => $vnp_Url
        ]
    ]);
    exit;
}

// Handle server info action
if (isset($input['action']) && $input['action'] === 'server_info') {
    $currentTime = new DateTime('now', new DateTimeZone('Asia/Ho_Chi_Minh'));
    $expireTime = clone $currentTime;
    $expireTime->add(new DateInterval('PT15M'));
    
    echo json_encode([
        'success' => true,
        'server_info' => [
            'current_time' => $currentTime->format('Y-m-d H:i:s'),
            'expire_time' => $expireTime->format('Y-m-d H:i:s'),
            'create_date_format' => $currentTime->format('YmdHis'),
            'expire_date_format' => $expireTime->format('YmdHis'),
            'timezone' => date_default_timezone_get(),
            'php_version' => PHP_VERSION,
            'server_software' => $_SERVER['SERVER_SOFTWARE'] ?? 'Unknown',
            'vnpay_config' => [
                'tmn_code' => $vnp_TmnCode,
                'return_url' => $vnp_Returnurl,
                'url' => $vnp_Url
            ]
        ]
    ]);
    exit;
}

// Handle simplified parameters for testing (without user_id requirement)
if (isset($input['orderId']) && isset($input['amount'])) {
    $orderId = $input['orderId'];
    $amount = $input['amount'];
    $orderInfo = isset($input['orderDesc']) ? $input['orderDesc'] : "Thanh toán đơn hàng #$orderId";
    $returnUrl = isset($input['returnUrl']) ? $input['returnUrl'] : $vnp_Returnurl;
    $customerName = isset($input['customerName']) ? $input['customerName'] : '';
    $customerPhone = isset($input['customerPhone']) ? $input['customerPhone'] : '';
    $customerEmail = isset($input['customerEmail']) ? $input['customerEmail'] : '';
    
    // For testing, we'll skip database validation
    $skipDBValidation = true;
} else {
    // Original validation for production use
    if (!isset($input['order_id']) || !isset($input['amount']) || !isset($input['user_id'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Missing required parameters']);
        exit;
    }
    
    $orderId = $input['order_id'];
    $amount = $input['amount'];
    $userId = $input['user_id'];
    $orderInfo = isset($input['order_info']) ? $input['order_info'] : "Thanh toán đơn hàng #$orderId";
    $returnUrl = $vnp_Returnurl;
    $customerName = isset($input['customer_name']) ? $input['customer_name'] : '';
    $customerPhone = isset($input['customer_phone']) ? $input['customer_phone'] : '';
    $customerEmail = isset($input['customer_email']) ? $input['customer_email'] : '';
    $skipDBValidation = false;
}

try {
    // Database validation (skip for testing)
    if (!$skipDBValidation) {
        $pdo = getDBConnection();
        if (!$pdo) {
            http_response_code(500);
            echo json_encode(['error' => 'Database connection failed']);
            exit;
        }

        // Kiểm tra đơn hàng có tồn tại và thuộc về user không
        $stmt = $pdo->prepare("SELECT id, total_amount, status FROM orders WHERE id = ? AND user_id = ?");
        $stmt->execute([$orderId, $userId]);
        $order = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$order) {
            http_response_code(404);
            echo json_encode(['error' => 'Order not found']);
            exit;
        }

        if ($order['status'] !== 'pending') {
            http_response_code(400);
            echo json_encode(['error' => 'Order cannot be paid']);
            exit;
        }

        if ($order['total_amount'] != $amount) {
            http_response_code(400);
            echo json_encode(['error' => 'Amount mismatch']);
            exit;
        }

        // Tạo hoặc cập nhật payment record
        $stmt = $pdo->prepare("
            INSERT INTO payments (order_id, payment_method, amount, status, created_at) 
            VALUES (?, 'VNPAY', ?, 'pending', NOW())
            ON DUPLICATE KEY UPDATE 
            amount = VALUES(amount), 
            status = 'pending', 
            updated_at = NOW()
        ");
        $stmt->execute([$orderId, $amount]);
    }

    // Tạo URL thanh toán VNPAY với thời gian chính xác
    $vnp_TxnRef = $orderId;
    $vnp_OrderInfo = $orderInfo;
    $vnp_Amount = $amount * 100; // VNPAY yêu cầu nhân 100
    $vnp_Locale = 'vn';
    $vnp_IpAddr = $_SERVER['REMOTE_ADDR'];
    
    // Sử dụng thời gian hiện tại chính xác
    $currentTime = new DateTime('now', new DateTimeZone('Asia/Ho_Chi_Minh'));
    $vnp_CreateDate = $currentTime->format('YmdHis');
    
    // Thời gian hết hạn: 15 phút từ hiện tại
    $expireTime = clone $currentTime;
    $expireTime->add(new DateInterval('PT15M'));
    $vnp_ExpireDate = $expireTime->format('YmdHis');

    // Tách tên khách hàng
    $vnp_Bill_FirstName = '';
    $vnp_Bill_LastName = '';
    if (!empty($customerName)) {
        $name = explode(' ', trim($customerName));
        if (count($name) > 1) {
            $vnp_Bill_FirstName = array_shift($name);
            $vnp_Bill_LastName = implode(' ', $name);
        } else {
            $vnp_Bill_FirstName = $customerName;
        }
    }

    // Tạo input data cho VNPAY - theo đúng thứ tự yêu cầu
    $inputData = array(
        "vnp_Version" => "2.1.0",
        "vnp_TmnCode" => $vnp_TmnCode,
        "vnp_Amount" => $vnp_Amount,
        "vnp_Command" => "pay",
        "vnp_CreateDate" => $vnp_CreateDate,
        "vnp_CurrCode" => "VND",
        "vnp_IpAddr" => $vnp_IpAddr,
        "vnp_Locale" => $vnp_Locale,
        "vnp_OrderInfo" => $vnp_OrderInfo,
        "vnp_OrderType" => "other",
        "vnp_ReturnUrl" => $returnUrl,
        "vnp_TxnRef" => $vnp_TxnRef,
        "vnp_ExpireDate" => $vnp_ExpireDate
    );

    // Thêm thông tin khách hàng nếu có
    if (!empty($customerPhone)) {
        $inputData['vnp_Bill_Mobile'] = $customerPhone;
    }
    if (!empty($customerEmail)) {
        $inputData['vnp_Bill_Email'] = $customerEmail;
    }
    if (!empty($vnp_Bill_FirstName)) {
        $inputData['vnp_Bill_FirstName'] = $vnp_Bill_FirstName;
    }
    if (!empty($vnp_Bill_LastName)) {
        $inputData['vnp_Bill_LastName'] = $vnp_Bill_LastName;
    }

    // Sắp xếp theo key
    ksort($inputData);

    // Tạo query string và hash data
    $query = "";
    $hashdata = "";
    $i = 0;
    foreach ($inputData as $key => $value) {
        if ($i == 1) {
            $hashdata .= '&' . urlencode($key) . "=" . urlencode($value);
        } else {
            $hashdata .= urlencode($key) . "=" . urlencode($value);
            $i = 1;
        }
        $query .= urlencode($key) . "=" . urlencode($value) . '&';
    }

    // Tạo secure hash
    $vnpSecureHash = hash_hmac('sha512', $hashdata, $vnp_HashSecret);
    
    // Tạo URL thanh toán cuối cùng
    $vnp_Url = $vnp_Url . "?" . $query . "vnp_SecureHash=" . $vnpSecureHash;

    // Debug log chi tiết
    error_log("=== VNPAY DEBUG START ===");
    error_log("Order ID: $orderId");
    error_log("Amount: $amount");
    error_log("Create Date: $vnp_CreateDate");
    error_log("Expire Date: $vnp_ExpireDate");
    error_log("Current Time: " . $currentTime->format('Y-m-d H:i:s'));
    error_log("Expire Time: " . $expireTime->format('Y-m-d H:i:s'));
    error_log("Hash Data: $hashdata");
    error_log("Secure Hash: $vnpSecureHash");
    error_log("Final URL: $vnp_Url");
    error_log("=== VNPAY DEBUG END ===");

    // Trả về kết quả
    $returnData = array(
        'success' => true,
        'code' => '00',
        'message' => 'Payment URL created successfully',
        'paymentUrl' => $vnp_Url,
        'transactionRef' => $vnp_TxnRef,
        'data' => array(
            'payment_url' => $vnp_Url,
            'order_id' => $orderId,
            'amount' => $amount,
            'create_date' => $vnp_CreateDate,
            'expire_date' => $vnp_ExpireDate,
            'current_time' => $currentTime->format('Y-m-d H:i:s'),
            'expire_time' => $expireTime->format('Y-m-d H:i:s'),
            'order_info' => $orderInfo,
            'debug' => array(
                'hash_data' => $hashdata,
                'secure_hash' => $vnpSecureHash,
                'timezone' => date_default_timezone_get(),
                'server_time' => date('Y-m-d H:i:s')
            )
        )
    );

    echo json_encode($returnData);

} catch (Exception $e) {
    error_log("VNPAY Payment Error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['error' => 'Internal server error: ' . $e->getMessage()]);
}
?> 