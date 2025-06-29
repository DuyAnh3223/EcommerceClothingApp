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
if (!isset($input['order_id']) || !isset($input['user_id'])) {
    http_response_code(400);
    echo json_encode(['error' => 'Missing required parameters']);
    exit;
}

$orderId = $input['order_id'];
$userId = $input['user_id'];

try {
    $pdo = getDBConnection();
    if (!$pdo) {
        http_response_code(500);
        echo json_encode(['error' => 'Database connection failed']);
        exit;
    }

    // Lấy thông tin đơn hàng và thanh toán
    $stmt = $pdo->prepare("
        SELECT 
            o.id as order_id,
            o.total_amount,
            o.status as order_status,
            o.created_at as order_date,
            p.status as payment_status,
            p.transaction_code,
            p.paid_at,
            p.payment_method
        FROM orders o 
        LEFT JOIN payments p ON o.id = p.order_id
        WHERE o.id = ? AND o.user_id = ?
    ");
    $stmt->execute([$orderId, $userId]);
    $result = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$result) {
        http_response_code(404);
        echo json_encode(['error' => 'Order not found']);
        exit;
    }

    // Trả về thông tin trạng thái
    $returnData = array(
        'success' => true,
        'data' => array(
            'order_id' => $result['order_id'],
            'total_amount' => $result['total_amount'],
            'order_status' => $result['order_status'],
            'payment_status' => $result['payment_status'],
            'payment_method' => $result['payment_method'],
            'transaction_code' => $result['transaction_code'],
            'order_date' => $result['order_date'],
            'paid_at' => $result['paid_at'],
            'is_paid' => ($result['payment_status'] === 'paid'),
            'is_confirmed' => ($result['order_status'] === 'confirmed')
        )
    );

    echo json_encode($returnData);

} catch (Exception $e) {
    error_log("Payment Status Check Error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['error' => 'Internal server error']);
}
?> 