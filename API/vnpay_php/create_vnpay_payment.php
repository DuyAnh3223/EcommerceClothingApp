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

// Validate input
if (!isset($input['order_id']) || !isset($input['amount']) || !isset($input['user_id'])) {
    http_response_code(400);
    echo json_encode(['error' => 'Missing required parameters']);
    exit;
}

$orderId = $input['order_id'];
$amount = $input['amount'];
$userId = $input['user_id'];
$orderInfo = isset($input['order_info']) ? $input['order_info'] : "Thanh toán đơn hàng #$orderId";
$customerName = isset($input['customer_name']) ? $input['customer_name'] : '';
$customerPhone = isset($input['customer_phone']) ? $input['customer_phone'] : '';
$customerEmail = isset($input['customer_email']) ? $input['customer_email'] : '';

try {
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

    // Tạo URL thanh toán VNPAY
    $vnp_TxnRef = $orderId;
    $vnp_OrderInfo = $orderInfo;
    $vnp_Amount = $amount * 100; // VNPAY yêu cầu nhân 100
    $vnp_Locale = 'vn';
    $vnp_IpAddr = $_SERVER['REMOTE_ADDR'];
    $vnp_ExpireDate = date('YmdHis', strtotime('+15 minutes'));

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

    // Tạo input data cho VNPAY
    $inputData = array(
        "vnp_Version" => "2.1.0",
        "vnp_TmnCode" => $vnp_TmnCode,
        "vnp_Amount" => $vnp_Amount,
        "vnp_Command" => "pay",
        "vnp_CreateDate" => date('YmdHis'),
        "vnp_CurrCode" => "VND",
        "vnp_IpAddr" => $vnp_IpAddr,
        "vnp_Locale" => $vnp_Locale,
        "vnp_OrderInfo" => $vnp_OrderInfo,
        "vnp_OrderType" => "other",
        "vnp_ReturnUrl" => $vnp_Returnurl,
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

    // Tạo query string
    $query = "";
    $i = 0;
    $hashdata = "";
    foreach ($inputData as $key => $value) {
        if ($i == 1) {
            $hashdata .= '&' . urlencode($key) . "=" . urlencode($value);
        } else {
            $hashdata .= urlencode($key) . "=" . urlencode($value);
            $i = 1;
        }
        $query .= urlencode($key) . "=" . urlencode($value) . '&';
    }

    // Tạo URL thanh toán
    $vnp_Url = $vnp_Url . "?" . $query;

    // Tạo secure hash
    if (isset($vnp_HashSecret)) {
        $vnpSecureHash = hash_hmac('sha512', $hashdata, $vnp_HashSecret);
        $vnp_Url .= 'vnp_SecureHash=' . $vnpSecureHash;
    }

    // Trả về kết quả
    $returnData = array(
        'success' => true,
        'code' => '00',
        'message' => 'Payment URL created successfully',
        'data' => array(
            'payment_url' => $vnp_Url,
            'order_id' => $orderId,
            'amount' => $amount,
            'expire_date' => $vnp_ExpireDate,
            'order_info' => $orderInfo
        )
    );

    echo json_encode($returnData);

} catch (Exception $e) {
    error_log("VNPAY Payment Error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['error' => 'Internal server error']);
}
?> 