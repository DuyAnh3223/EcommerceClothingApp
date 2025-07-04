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
    // Bắt đầu transaction
    $conn->begin_transaction();
    
    // Lấy danh sách payments BACoin chưa có mã giao dịch
    $sql = "SELECT id, order_id, amount, paid_at FROM payments WHERE payment_method = 'BACoin' AND transaction_code IS NULL AND status = 'paid'";
    $result = $conn->query($sql);
    
    $updated_payments = [];
    $update_count = 0;
    
    while ($row = $result->fetch_assoc()) {
        $payment_id = $row['id'];
        $order_id = $row['order_id'];
        $amount = $row['amount'];
        $paid_at = $row['paid_at'];
        
        // Tạo mã giao dịch mới
        $transaction_code = generateTransactionCode('BACoin');
        
        // Cập nhật mã giao dịch
        $update_sql = "UPDATE payments SET transaction_code = ? WHERE id = ?";
        $update_stmt = $conn->prepare($update_sql);
        $update_stmt->bind_param("si", $transaction_code, $payment_id);
        
        if ($update_stmt->execute()) {
            $update_count++;
            $updated_payments[] = [
                'payment_id' => (int)$payment_id,
                'order_id' => (int)$order_id,
                'amount' => (float)$amount,
                'paid_at' => $paid_at,
                'transaction_code' => $transaction_code
            ];
        }
        
        $update_stmt->close();
    }
    
    // Commit transaction
    $conn->commit();
    
    // Lấy thống kê sau khi cập nhật
    $total_bacoin_sql = "SELECT COUNT(*) as total FROM payments WHERE payment_method = 'BACoin'";
    $total_result = $conn->query($total_bacoin_sql);
    $total_bacoin = $total_result->fetch_assoc()['total'];
    
    $total_with_code_sql = "SELECT COUNT(*) as total FROM payments WHERE payment_method = 'BACoin' AND transaction_code IS NOT NULL";
    $total_with_code_result = $conn->query($total_with_code_sql);
    $total_with_code = $total_with_code_result->fetch_assoc()['total'];
    
    echo json_encode([
        'success' => true,
        'message' => "Đã cập nhật mã giao dịch cho $update_count thanh toán BACoin",
        'updated_payments' => $updated_payments,
        'statistics' => [
            'total_bacoin_payments' => (int)$total_bacoin,
            'total_with_transaction_code' => (int)$total_with_code,
            'percentage_with_code' => $total_bacoin > 0 ? round(($total_with_code / $total_bacoin) * 100, 2) : 0,
            'updated_count' => $update_count
        ]
    ]);
    
} catch (Exception $e) {
    // Rollback nếu có lỗi
    $conn->rollback();
    
    echo json_encode([
        'success' => false,
        'message' => 'Server error: ' . $e->getMessage()
    ]);
}

$conn->close();
?> 