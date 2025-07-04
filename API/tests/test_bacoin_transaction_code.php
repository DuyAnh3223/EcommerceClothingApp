<?php
require_once '../config/db_connect.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Hàm tạo mã giao dịch ngẫu nhiên
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
        case 'BACoin':
            $prefix = 'BACOIN';
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
    // Test tạo mã giao dịch cho BACoin
    $bacoin_codes = [];
    for ($i = 0; $i < 5; $i++) {
        $bacoin_codes[] = [
            'iteration' => $i + 1,
            'transaction_code' => generateTransactionCode('BACoin'),
            'length' => strlen(generateTransactionCode('BACoin')),
            'timestamp' => date('Y-m-d H:i:s')
        ];
    }
    
    // Lấy danh sách payments có mã giao dịch BACoin
    $sql = "SELECT 
                p.id,
                p.order_id,
                p.payment_method,
                p.amount,
                p.status,
                p.transaction_code,
                p.paid_at,
                p.amount_bacoin,
                o.status as order_status
            FROM payments p
            JOIN orders o ON p.order_id = o.id
            WHERE p.payment_method = 'BACoin' AND p.transaction_code IS NOT NULL
            ORDER BY p.id DESC
            LIMIT 10";
    
    $result = $conn->query($sql);
    
    $bacoin_payments = [];
    while ($row = $result->fetch_assoc()) {
        $bacoin_payments[] = [
            'payment_id' => (int)$row['id'],
            'order_id' => (int)$row['order_id'],
            'payment_method' => $row['payment_method'],
            'amount' => (float)$row['amount'],
            'amount_bacoin' => (float)$row['amount_bacoin'],
            'status' => $row['status'],
            'transaction_code' => $row['transaction_code'],
            'paid_at' => $row['paid_at'],
            'order_status' => $row['order_status']
        ];
    }
    
    // Lấy tổng số payments BACoin
    $total_bacoin_sql = "SELECT COUNT(*) as total FROM payments WHERE payment_method = 'BACoin'";
    $total_result = $conn->query($total_bacoin_sql);
    $total_bacoin = $total_result->fetch_assoc()['total'];
    
    // Lấy tổng số payments BACoin có mã giao dịch
    $total_with_code_sql = "SELECT COUNT(*) as total FROM payments WHERE payment_method = 'BACoin' AND transaction_code IS NOT NULL";
    $total_with_code_result = $conn->query($total_with_code_sql);
    $total_with_code = $total_with_code_result->fetch_assoc()['total'];
    
    echo json_encode([
        'success' => true,
        'message' => 'BACoin transaction code test completed successfully',
        'test_codes' => $bacoin_codes,
        'existing_bacoin_payments' => $bacoin_payments,
        'statistics' => [
            'total_bacoin_payments' => (int)$total_bacoin,
            'total_with_transaction_code' => (int)$total_with_code,
            'percentage_with_code' => $total_bacoin > 0 ? round(($total_with_code / $total_bacoin) * 100, 2) : 0
        ]
    ]);
    
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Server error: ' . $e->getMessage()
    ]);
}

$conn->close();
?> 