<?php
header('Content-Type: text/html; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    exit(0);
}

require_once("./config.php");

try {
    // Lấy dữ liệu từ request
    $vnp_SecureHash = $_GET['vnp_SecureHash'] ?? '';
    $inputData = array();
    
    foreach ($_GET as $key => $value) {
        if (substr($key, 0, 4) == "vnp_") {
            $inputData[$key] = $value;
        }
    }
    
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
    
    // Xử lý kết quả thanh toán
    $orderId = $_GET['vnp_TxnRef'] ?? '';
    $amount = isset($_GET['vnp_Amount']) ? $_GET['vnp_Amount'] / 100 : 0; // Chia 100 vì VNPAY trả về số tiền đã nhân 100
    $responseCode = $_GET['vnp_ResponseCode'] ?? '';
    $transactionNo = $_GET['vnp_TransactionNo'] ?? '';
    $bankCode = $_GET['vnp_BankCode'] ?? '';
    $payDate = $_GET['vnp_PayDate'] ?? '';
    $orderInfo = $_GET['vnp_OrderInfo'] ?? '';
    
    $isValidSignature = ($secureHash == $vnp_SecureHash);
    $isSuccess = ($responseCode == '00');
    
    $result = [
        'success' => $isValidSignature && $isSuccess,
        'order_id' => $orderId,
        'amount' => $amount,
        'response_code' => $responseCode,
        'transaction_no' => $transactionNo,
        'bank_code' => $bankCode,
        'pay_date' => $payDate,
        'order_info' => $orderInfo,
        'is_valid_signature' => $isValidSignature,
        'message' => ''
    ];
    
    // Cập nhật database
    if ($isValidSignature) {
        $pdo = getDBConnection();
        if ($pdo) {
            if ($isSuccess) {
                // Thanh toán thành công
                $stmt = $pdo->prepare("UPDATE payments SET status = 'paid', transaction_code = ?, paid_at = NOW() WHERE order_id = ? AND payment_method = 'VNPAY'");
                $stmt->execute([$transactionNo, $orderId]);
                
                // Cập nhật trạng thái đơn hàng
                $stmt = $pdo->prepare("UPDATE orders SET status = 'confirmed', updated_at = NOW() WHERE id = ?");
                $stmt->execute([$orderId]);
                
                // Tạo thông báo cho khách hàng
                $stmt = $pdo->prepare("SELECT user_id FROM orders WHERE id = ?");
                $stmt->execute([$orderId]);
                $order = $stmt->fetch();
                
                if ($order) {
                    $stmt = $pdo->prepare("INSERT INTO notifications (user_id, title, content, type, created_at) VALUES (?, ?, ?, 'order_status', NOW())");
                    $stmt->execute([
                        $order['user_id'],
                        'Thanh toán thành công',
                        "Đơn hàng #$orderId đã được thanh toán thành công qua VNPAY. Mã giao dịch: $transactionNo",
                    ]);
                }
                
                $result['message'] = 'Thanh toán thành công';
            } else {
                // Thanh toán thất bại
                $stmt = $pdo->prepare("UPDATE payments SET status = 'failed', updated_at = NOW() WHERE order_id = ? AND payment_method = 'VNPAY'");
                $stmt->execute([$orderId]);
                
                $result['message'] = 'Thanh toán thất bại';
            }
        } else {
            $result['message'] = 'Lỗi kết nối database';
        }
    } else {
        $result['message'] = 'Chữ ký không hợp lệ';
    }
    
    // Hiển thị trang kết quả đẹp thay vì JSON
    displayPaymentResult($result);
    
} catch (Exception $e) {
    error_log("VNPAY Return API Error: " . $e->getMessage());
    displayPaymentResult([
        'success' => false,
        'message' => 'Lỗi xử lý thanh toán: ' . $e->getMessage()
    ]);
}

function displayPaymentResult($result) {
    $isSuccess = $result['success'] ?? false;
    $orderId = $result['order_id'] ?? '';
    $amount = $result['amount'] ?? 0;
    $transactionNo = $result['transaction_no'] ?? '';
    $bankCode = $result['bank_code'] ?? '';
    $payDate = $result['pay_date'] ?? '';
    $message = $result['message'] ?? '';
    
    // Format số tiền
    $formattedAmount = number_format($amount, 0, ',', '.') . ' VNĐ';
    
    // Format ngày thanh toán
    $formattedPayDate = '';
    if ($payDate) {
        $year = substr($payDate, 0, 4);
        $month = substr($payDate, 4, 2);
        $day = substr($payDate, 6, 2);
        $hour = substr($payDate, 8, 2);
        $minute = substr($payDate, 10, 2);
        $second = substr($payDate, 12, 2);
        $formattedPayDate = "$day/$month/$year $hour:$minute:$second";
    }
    
    ?>
    <!DOCTYPE html>
    <html lang="vi">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title><?= $isSuccess ? 'Thanh toán thành công' : 'Thanh toán thất bại' ?> - Ecommerce Clothing App</title>
        <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
        <style>
            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }
            
            body {
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                min-height: 100vh;
                display: flex;
                align-items: center;
                justify-content: center;
                padding: 20px;
            }
            
            .container {
                background: white;
                border-radius: 20px;
                box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
                padding: 40px;
                max-width: 500px;
                width: 100%;
                text-align: center;
                position: relative;
                overflow: hidden;
            }
            
            .container::before {
                content: '';
                position: absolute;
                top: 0;
                left: 0;
                right: 0;
                height: 4px;
                background: <?= $isSuccess ? 'linear-gradient(90deg, #4CAF50, #45a049)' : 'linear-gradient(90deg, #f44336, #d32f2f)' ?>;
            }
            
            .icon {
                width: 80px;
                height: 80px;
                border-radius: 50%;
                display: flex;
                align-items: center;
                justify-content: center;
                margin: 0 auto 20px;
                font-size: 40px;
                color: white;
                background: <?= $isSuccess ? 'linear-gradient(135deg, #4CAF50, #45a049)' : 'linear-gradient(135deg, #f44336, #d32f2f)' ?>;
                box-shadow: 0 10px 20px rgba(0, 0, 0, 0.1);
            }
            
            .title {
                font-size: 28px;
                font-weight: 700;
                color: #333;
                margin-bottom: 10px;
            }
            
            .subtitle {
                font-size: 16px;
                color: #666;
                margin-bottom: 30px;
            }
            
            .details {
                background: #f8f9fa;
                border-radius: 15px;
                padding: 25px;
                margin-bottom: 30px;
                text-align: left;
            }
            
            .detail-row {
                display: flex;
                justify-content: space-between;
                align-items: center;
                padding: 10px 0;
                border-bottom: 1px solid #e9ecef;
            }
            
            .detail-row:last-child {
                border-bottom: none;
            }
            
            .detail-label {
                font-weight: 600;
                color: #555;
                font-size: 14px;
            }
            
            .detail-value {
                font-weight: 700;
                color: #333;
                font-size: 14px;
            }
            
            .amount {
                font-size: 18px;
                color: #4CAF50;
            }
            
            .btn {
                display: inline-block;
                padding: 15px 30px;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                text-decoration: none;
                border-radius: 50px;
                font-weight: 600;
                font-size: 16px;
                transition: all 0.3s ease;
                box-shadow: 0 5px 15px rgba(102, 126, 234, 0.4);
                border: none;
                cursor: pointer;
            }
            
            .btn:hover {
                transform: translateY(-2px);
                box-shadow: 0 8px 25px rgba(102, 126, 234, 0.6);
            }
            
            .btn i {
                margin-right: 8px;
            }
            
            .error-message {
                background: #ffebee;
                color: #c62828;
                padding: 15px;
                border-radius: 10px;
                margin-bottom: 20px;
                border-left: 4px solid #f44336;
            }
            
            @media (max-width: 480px) {
                .container {
                    padding: 30px 20px;
                }
                
                .title {
                    font-size: 24px;
                }
                
                .details {
                    padding: 20px;
                }
                
                .btn {
                    padding: 12px 25px;
                    font-size: 14px;
                }
            }
            
            .thank-you-message {
                text-align: center;
                margin-top: 30px;
                padding: 25px;
                background: linear-gradient(135deg, #ff9a9e 0%, #fecfef 100%);
                border-radius: 15px;
                color: #333;
            }
            
            .thank-you-message i {
                font-size: 40px;
                color: #e91e63;
                margin-bottom: 15px;
                animation: heartbeat 1.5s ease-in-out infinite;
            }
            
            .thank-you-message p {
                font-size: 16px;
                font-weight: 600;
                margin-bottom: 8px;
                color: #333;
            }
            
            .thank-you-message .sub-message {
                font-size: 14px;
                font-weight: 400;
                color: #666;
                margin-bottom: 0;
            }
            
            @keyframes heartbeat {
                0% { transform: scale(1); }
                50% { transform: scale(1.1); }
                100% { transform: scale(1); }
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="icon">
                <?php if ($isSuccess): ?>
                    <i class="fas fa-check"></i>
                <?php else: ?>
                    <i class="fas fa-times"></i>
                <?php endif; ?>
            </div>
            
            <h1 class="title">
                <?php if ($isSuccess): ?>
                    Thanh toán thành công!
                <?php else: ?>
                    Thanh toán thất bại
                <?php endif; ?>
            </h1>
            
            <p class="subtitle">
                <?php if ($isSuccess): ?>
                    Cảm ơn bạn đã mua hàng. Đơn hàng của bạn đã được xác nhận.
                <?php else: ?>
                    Có lỗi xảy ra trong quá trình thanh toán. Vui lòng thử lại.
                <?php endif; ?>
            </p>
            
            <?php if (!$isSuccess && $message): ?>
                <div class="error-message">
                    <i class="fas fa-exclamation-triangle"></i>
                    <?= htmlspecialchars($message) ?>
                </div>
            <?php endif; ?>
            
            <?php if ($isSuccess): ?>
                <div class="details">
                    <div class="detail-row">
                        <span class="detail-label">Mã đơn hàng:</span>
                        <span class="detail-value">#<?= htmlspecialchars($orderId) ?></span>
                    </div>
                    
                    <div class="detail-row">
                        <span class="detail-label">Số tiền:</span>
                        <span class="detail-value amount"><?= htmlspecialchars($formattedAmount) ?></span>
                    </div>
                    
                    <?php if ($transactionNo): ?>
                    <div class="detail-row">
                        <span class="detail-label">Mã giao dịch:</span>
                        <span class="detail-value"><?= htmlspecialchars($transactionNo) ?></span>
                    </div>
                    <?php endif; ?>
                    
                    <?php if ($bankCode): ?>
                    <div class="detail-row">
                        <span class="detail-label">Ngân hàng:</span>
                        <span class="detail-value"><?= htmlspecialchars($bankCode) ?></span>
                    </div>
                    <?php endif; ?>
                    
                    <?php if ($formattedPayDate): ?>
                    <div class="detail-row">
                        <span class="detail-label">Thời gian:</span>
                        <span class="detail-value"><?= htmlspecialchars($formattedPayDate) ?></span>
                    </div>
                    <?php endif; ?>
                </div>
            <?php endif; ?>
            
            <div class="thank-you-message">
                <i class="fas fa-heart"></i>
                <p>Cảm ơn bạn đã tin tưởng và mua sắm tại cửa hàng của chúng tôi!</p>
                <p class="sub-message">Chúng tôi sẽ liên hệ với bạn sớm nhất để xác nhận đơn hàng.</p>
            </div>
        </div>
        
        <script>
            // Auto redirect sau 15 giây về trang chủ
            setTimeout(function() {
                window.location.href = 'http://localhost/EcommerceClothingApp/userfe/';
            }, 15000);
        </script>
    </body>
    </html>
    <?php
}
?> 