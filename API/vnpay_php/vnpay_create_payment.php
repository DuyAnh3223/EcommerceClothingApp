<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    exit(0);
}

error_reporting(E_ALL & ~E_NOTICE & ~E_DEPRECATED);
date_default_timezone_set('Asia/Ho_Chi_Minh');

/**
 * Description of vnpay_ajax
 *
 * @author xonv
 */
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
if (!isset($input['order_id']) || !isset($input['amount']) || !isset($input['order_info'])) {
    http_response_code(400);
    echo json_encode(['error' => 'Missing required parameters']);
    exit;
}

$vnp_TxnRef = $input['order_id']; // Mã đơn hàng
$vnp_OrderInfo = $input['order_info']; // Mô tả đơn hàng
$vnp_Amount = $input['amount'] * 100; // Số tiền (VNPAY yêu cầu nhân 100)
$vnp_Locale = isset($input['language']) ? $input['language'] : 'vn';
$vnp_BankCode = isset($input['bank_code']) ? $input['bank_code'] : '';
$vnp_IpAddr = $_SERVER['REMOTE_ADDR'];

// Thông tin khách hàng (nếu có)
$vnp_Bill_Mobile = isset($input['customer_phone']) ? $input['customer_phone'] : '';
$vnp_Bill_Email = isset($input['customer_email']) ? $input['customer_email'] : '';
$vnp_Bill_FirstName = isset($input['customer_name']) ? $input['customer_name'] : '';
$vnp_Bill_LastName = '';

// Tách tên thành first name và last name
if (!empty($vnp_Bill_FirstName)) {
    $name = explode(' ', trim($vnp_Bill_FirstName));
    if (count($name) > 1) {
        $vnp_Bill_FirstName = array_shift($name);
        $vnp_Bill_LastName = implode(' ', $name);
    }
}

// Thời gian hết hạn (15 phút)
$vnp_ExpireDate = date('YmdHis', strtotime('+15 minutes'));

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
if (!empty($vnp_Bill_Mobile)) {
    $inputData['vnp_Bill_Mobile'] = $vnp_Bill_Mobile;
}
if (!empty($vnp_Bill_Email)) {
    $inputData['vnp_Bill_Email'] = $vnp_Bill_Email;
}
if (!empty($vnp_Bill_FirstName)) {
    $inputData['vnp_Bill_FirstName'] = $vnp_Bill_FirstName;
}
if (!empty($vnp_Bill_LastName)) {
    $inputData['vnp_Bill_LastName'] = $vnp_Bill_LastName;
}

// Thêm bank code nếu có
if (!empty($vnp_BankCode)) {
    $inputData['vnp_BankCode'] = $vnp_BankCode;
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

// Lưu thông tin thanh toán vào database
try {
    $pdo = getDBConnection();
    if ($pdo) {
        // Kiểm tra xem đơn hàng đã tồn tại chưa
        $stmt = $pdo->prepare("SELECT id FROM orders WHERE id = ?");
        $stmt->execute([$vnp_TxnRef]);
        
        if ($stmt->rowCount() > 0) {
            // Cập nhật trạng thái thanh toán
            $stmt = $pdo->prepare("UPDATE payments SET status = 'pending', updated_at = NOW() WHERE order_id = ? AND payment_method = 'VNPAY'");
            $stmt->execute([$vnp_TxnRef]);
        }
    }
} catch (Exception $e) {
    // Log error nhưng không dừng quá trình
    error_log("Database error: " . $e->getMessage());
}

// Trả về kết quả
$returnData = array(
    'success' => true,
    'code' => '00',
    'message' => 'Payment URL created successfully',
    'data' => array(
        'payment_url' => $vnp_Url,
        'order_id' => $vnp_TxnRef,
        'amount' => $input['amount'],
        'expire_date' => $vnp_ExpireDate
    )
);

echo json_encode($returnData);
?>
