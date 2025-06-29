<?php
header('Content-Type: application/json');

/* Payment Notify
 * IPN URL: Ghi nhận kết quả thanh toán từ VNPAY
 * Các bước thực hiện:
 * Kiểm tra checksum 
 * Tìm giao dịch trong database
 * Kiểm tra số tiền giữa hai hệ thống
 * Kiểm tra tình trạng của giao dịch trước khi cập nhật
 * Cập nhật kết quả vào Database
 * Trả kết quả ghi nhận lại cho VNPAY
 */

require_once("./config.php");

$inputData = array();
$returnData = array();

// Lấy dữ liệu từ VNPAY
foreach ($_GET as $key => $value) {
    if (substr($key, 0, 4) == "vnp_") {
        $inputData[$key] = $value;
    }
}

$vnp_SecureHash = $inputData['vnp_SecureHash'];
unset($inputData['vnp_SecureHash']);
ksort($inputData);
$i = 0;
$hashData = "";
foreach ($inputData as $key => $value) {
    if ($i == 1) {
        $hashData = $hashData . '&' . urlencode($key) . "=" . urlencode($value);
    } else {
        $hashData = $hashData . urlencode($key) . "=" . urlencode($value);
        $i = 1;
    }
}

$secureHash = hash_hmac('sha512', $hashData, $vnp_HashSecret);
$vnpTranId = $inputData['vnp_TransactionNo']; // Mã giao dịch tại VNPAY
$vnp_BankCode = $inputData['vnp_BankCode']; // Ngân hàng thanh toán
$vnp_Amount = $inputData['vnp_Amount'] / 100; // Số tiền thanh toán VNPAY phản hồi
$orderId = $inputData['vnp_TxnRef']; // Mã đơn hàng
$responseCode = $inputData['vnp_ResponseCode']; // Mã phản hồi

try {
    // Kiểm tra checksum của dữ liệu
    if ($secureHash == $vnp_SecureHash) {
        $pdo = getDBConnection();
        
        if ($pdo) {
            // Lấy thông tin đơn hàng và thanh toán từ database
            $stmt = $pdo->prepare("
                SELECT o.id, o.total_amount, o.status, p.status as payment_status, p.id as payment_id
                FROM orders o 
                LEFT JOIN payments p ON o.id = p.order_id AND p.payment_method = 'VNPAY'
                WHERE o.id = ?
            ");
            $stmt->execute([$orderId]);
            $order = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if ($order) {
                // Kiểm tra số tiền thanh toán
                if ($order['total_amount'] == $vnp_Amount) {
                    // Kiểm tra trạng thái thanh toán hiện tại
                    if ($order['payment_status'] == 'pending' || $order['payment_status'] == null) {
                        if ($responseCode == '00') {
                            // Thanh toán thành công
                            $stmt = $pdo->prepare("
                                UPDATE payments 
                                SET status = 'paid', transaction_code = ?, paid_at = NOW(), updated_at = NOW() 
                                WHERE order_id = ? AND payment_method = 'VNPAY'
                            ");
                            $stmt->execute([$vnpTranId, $orderId]);
                            
                            // Cập nhật trạng thái đơn hàng
                            $stmt = $pdo->prepare("
                                UPDATE orders 
                                SET status = 'confirmed', updated_at = NOW() 
                                WHERE id = ?
                            ");
                            $stmt->execute([$orderId]);
                            
                            // Tạo thông báo cho khách hàng
                            $stmt = $pdo->prepare("
                                INSERT INTO notifications (user_id, title, content, type, created_at) 
                                SELECT user_id, 'Thanh toán thành công', ?, 'order_status', NOW()
                                FROM orders WHERE id = ?
                            ");
                            $stmt->execute([
                                "Đơn hàng #$orderId đã được thanh toán thành công qua VNPAY. Mã giao dịch: $vnpTranId",
                                $orderId
                            ]);
                            
                            $returnData['RspCode'] = '00';
                            $returnData['Message'] = 'Confirm Success';
                        } else {
                            // Thanh toán thất bại
                            $stmt = $pdo->prepare("
                                UPDATE payments 
                                SET status = 'failed', updated_at = NOW() 
                                WHERE order_id = ? AND payment_method = 'VNPAY'
                            ");
                            $stmt->execute([$orderId]);
                            
                            $returnData['RspCode'] = '00';
                            $returnData['Message'] = 'Payment Failed - Confirmed';
                        }
                    } else {
                        $returnData['RspCode'] = '02';
                        $returnData['Message'] = 'Order already confirmed';
                    }
                } else {
                    $returnData['RspCode'] = '04';
                    $returnData['Message'] = 'Invalid amount';
                }
            } else {
                $returnData['RspCode'] = '01';
                $returnData['Message'] = 'Order not found';
            }
        } else {
            $returnData['RspCode'] = '99';
            $returnData['Message'] = 'Database connection error';
        }
    } else {
        $returnData['RspCode'] = '97';
        $returnData['Message'] = 'Invalid signature';
    }
} catch (Exception $e) {
    error_log("VNPAY IPN Error: " . $e->getMessage());
    $returnData['RspCode'] = '99';
    $returnData['Message'] = 'Unknown error';
}

// Trả lại VNPAY theo định dạng JSON
echo json_encode($returnData);
?>
