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

// Hàm tạo mã giao dịch ngẫu nhiên (copy từ update_order.php)
function generateTransactionCode($paymentMethod) {
    $prefix = '';
    switch ($paymentMethod) {
        case 'Momo':
            $prefix = 'MOMO';
            break;
        case 'VNPAY':
            $prefix = 'VNPAY';
            break;
        case 'Bank':
            $prefix = 'BANK';
            break;
        case 'COD':
            $prefix = 'COD';
            break;
        default:
            $prefix = 'TXN';
    }
    
    // Tạo 8 số ngẫu nhiên
    $randomNumbers = str_pad(mt_rand(1, 99999999), 8, '0', STR_PAD_LEFT);
    
    // Thêm timestamp để đảm bảo unique
    $timestamp = date('YmdHis');
    
    return $prefix . $timestamp . $randomNumbers;
}

try {
    // Test tạo mã giao dịch cho các phương thức khác nhau
    $testMethods = ['Momo', 'VNPAY', 'Bank', 'COD', 'Other'];
    $testResults = [];
    
    foreach ($testMethods as $method) {
        $testResults[] = [
            'payment_method' => $method,
            'transaction_code' => generateTransactionCode($method),
            'length' => strlen(generateTransactionCode($method))
        ];
    }
    
    // Lấy danh sách payments có mã giao dịch
    $conn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);
    
    if ($conn->connect_error) {
        sendResponse(false, 'Connection failed: ' . $conn->connect_error, null, 500);
        exit();
    }
    
    $sql = "SELECT 
                p.id,
                p.order_id,
                p.payment_method,
                p.amount,
                p.status,
                p.transaction_code,
                p.paid_at,
                o.status as order_status
            FROM payments p
            JOIN orders o ON p.order_id = o.id
            WHERE p.transaction_code IS NOT NULL
            ORDER BY p.id DESC
            LIMIT 10";
    
    $result = $conn->query($sql);
    
    $payments = [];
    while ($row = $result->fetch_assoc()) {
        $payments[] = [
            'payment_id' => (int)$row['id'],
            'order_id' => (int)$row['order_id'],
            'payment_method' => $row['payment_method'],
            'amount' => (float)$row['amount'],
            'status' => $row['status'],
            'transaction_code' => $row['transaction_code'],
            'paid_at' => $row['paid_at'],
            'order_status' => $row['order_status']
        ];
    }
    
    $conn->close();
    
    sendResponse(true, 'Transaction code test completed successfully', [
        'test_codes' => $testResults,
        'existing_payments' => $payments,
        'total_payments_with_codes' => count($payments)
    ]);
    
} catch (Exception $e) {
    sendResponse(false, 'Server error: ' . $e->getMessage(), null, 500);
}
?> 