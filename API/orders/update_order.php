<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");
require_once '../config/db_connect.php';

if (
    $_SERVER['REQUEST_METHOD'] == 'OPTIONS'
) {
    http_response_code(200);
    exit();
}

$data = json_decode(file_get_contents("php://input"), true);

$order_id = $data['order_id'] ?? null;
$status = $data['status'] ?? null;

if (!$order_id || !$status) {
    echo json_encode(["success" => false, "message" => "Thiếu order_id hoặc status"]);
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
        default:
            $prefix = 'TXN';
    }
    
    // Tạo 8 số ngẫu nhiên
    $randomNumbers = str_pad(mt_rand(1, 99999999), 8, '0', STR_PAD_LEFT);
    
    // Thêm timestamp để đảm bảo unique
    $timestamp = date('YmdHis');
    
    return $prefix . $timestamp . $randomNumbers;
}

// Bắt đầu transaction
$conn->begin_transaction();

try {
    // Cập nhật trạng thái đơn hàng
    $stmt = $conn->prepare("UPDATE orders SET status = ? WHERE id = ?");
    $stmt->bind_param("si", $status, $order_id);
    $stmt->execute();
    $stmt->close();

    // Cập nhật trạng thái thanh toán tương ứng
    $payment_status = 'pending'; // Mặc định
    $paid_at = null;
    $transaction_code = null;
    
    switch ($status) {
        case 'confirmed':
            $payment_status = 'paid';
            $paid_at = date('Y-m-d H:i:s');
            break;
        case 'shipping':
            $payment_status = 'paid';
            $paid_at = date('Y-m-d H:i:s');
            break;
        case 'delivered':
            $payment_status = 'paid';
            $paid_at = date('Y-m-d H:i:s');
            break;
        case 'cancelled':
            $payment_status = 'failed';
            break;
        default:
            $payment_status = 'pending';
    }

    // Nếu trạng thái chuyển thành paid, tạo mã giao dịch
    if ($payment_status === 'paid') {
        // Lấy phương thức thanh toán từ bảng payments
        $payment_method_sql = "SELECT payment_method FROM payments WHERE order_id = ?";
        $payment_method_stmt = $conn->prepare($payment_method_sql);
        $payment_method_stmt->bind_param("i", $order_id);
        $payment_method_stmt->execute();
        $payment_method_result = $payment_method_stmt->get_result();
        $payment_method_row = $payment_method_result->fetch_assoc();
        $payment_method = $payment_method_row['payment_method'] ?? 'COD';
        $payment_method_stmt->close();
        
        // Tạo mã giao dịch ngẫu nhiên
        $transaction_code = generateTransactionCode($payment_method);
    }

    // Cập nhật trạng thái thanh toán và mã giao dịch
    $payment_stmt = $conn->prepare("UPDATE payments SET status = ?, paid_at = ?, transaction_code = ? WHERE order_id = ?");
    $payment_stmt->bind_param("sssi", $payment_status, $paid_at, $transaction_code, $order_id);
    $payment_stmt->execute();
    $payment_stmt->close();

    // Commit transaction
    $conn->commit();

    // Send notification to user about order status change
    $notificationData = json_encode([
        'order_id' => $order_id,
        'status' => $status
    ]);
    
    $notificationUrl = 'http://127.0.0.1/EcommerceClothingApp/API/notifications/send_order_notification.php';
    $notificationContext = stream_context_create([
        'http' => [
            'method' => 'POST',
            'header' => 'Content-Type: application/json',
            'content' => $notificationData
        ]
    ]);
    
    // Send notification asynchronously (don't wait for response)
    @file_get_contents($notificationUrl, false, $notificationContext);
    
    $response_data = [
        "success" => true, 
        "message" => "Cập nhật trạng thái đơn hàng và thanh toán thành công",
        "order_status" => $status,
        "payment_status" => $payment_status
    ];
    
    // Thêm mã giao dịch vào response nếu có
    if ($transaction_code) {
        $response_data["transaction_code"] = $transaction_code;
    }
    
    echo json_encode($response_data);

} catch (Exception $e) {
    // Rollback transaction nếu có lỗi
    $conn->rollback();
    echo json_encode([
        "success" => false, 
        "message" => "Lỗi: " . $e->getMessage()
    ]);
}

$conn->close();
?>