<?php
require_once 'config/config.php';
require_once 'utils/response.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    $conn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);
    
    if ($conn->connect_error) {
        sendResponse(false, 'Connection failed: ' . $conn->connect_error, null, 500);
        exit();
    }
    
    // Lấy danh sách đơn hàng và trạng thái thanh toán tương ứng
    $sql = "SELECT 
                o.id as order_id,
                o.status as order_status,
                o.total_amount,
                p.id as payment_id,
                p.status as payment_status,
                p.paid_at,
                u.username
            FROM orders o
            JOIN payments p ON o.id = p.order_id
            JOIN users u ON o.user_id = u.id
            ORDER BY o.id DESC
            LIMIT 10";
    
    $result = $conn->query($sql);
    
    $orders = [];
    while ($row = $result->fetch_assoc()) {
        $orders[] = [
            'order_id' => (int)$row['order_id'],
            'order_status' => $row['order_status'],
            'payment_id' => (int)$row['payment_id'],
            'payment_status' => $row['payment_status'],
            'total_amount' => (float)$row['total_amount'],
            'paid_at' => $row['paid_at'],
            'username' => $row['username']
        ];
    }
    
    $conn->close();
    
    sendResponse(true, 'Payment status test data retrieved successfully', [
        'orders' => $orders,
        'total_count' => count($orders)
    ]);
    
} catch (Exception $e) {
    sendResponse(false, 'Server error: ' . $e->getMessage(), null, 500);
}
?> 