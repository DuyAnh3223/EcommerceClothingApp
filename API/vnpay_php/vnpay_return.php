<!DOCTYPE html>
<html lang="vi">
    <head>
        <meta charset="utf-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <!-- The above 3 meta tags *must* come first in the head; any other head content must come *after* these tags -->
        <meta name="description" content="">
        <meta name="author" content="">
        <title>Kết quả thanh toán VNPAY</title>
        <!-- Bootstrap core CSS -->
        <link href="/vnpay_php/assets/bootstrap.min.css" rel="stylesheet"/>
        <!-- Custom styles for this template -->
        <link href="/vnpay_php/assets/jumbotron-narrow.css" rel="stylesheet">         
        <script src="/vnpay_php/assets/jquery-1.11.3.min.js"></script>
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
        <style>
            .payment-result {
                max-width: 600px;
                margin: 50px auto;
                padding: 30px;
                border-radius: 10px;
                box-shadow: 0 0 20px rgba(0,0,0,0.1);
                background: white;
            }
            .success { border-left: 5px solid #28a745; }
            .error { border-left: 5px solid #dc3545; }
            .pending { border-left: 5px solid #ffc107; }
            .result-icon {
                font-size: 48px;
                margin-bottom: 20px;
            }
            .btn-back {
                margin-top: 20px;
            }
            body {
                background-color: #f8f9fa;
            }
        </style>
    </head>
    <body>
        <?php
        require_once("./config.php");
        
        $vnp_SecureHash = $_GET['vnp_SecureHash'];
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
        $orderId = $_GET['vnp_TxnRef'];
        $amount = $_GET['vnp_Amount'] / 100; // Chia 100 vì VNPAY trả về số tiền đã nhân 100
        $responseCode = $_GET['vnp_ResponseCode'];
        $transactionNo = $_GET['vnp_TransactionNo'];
        $bankCode = $_GET['vnp_BankCode'];
        $payDate = $_GET['vnp_PayDate'];
        $orderInfo = $_GET['vnp_OrderInfo'];
        
        $isValidSignature = ($secureHash == $vnp_SecureHash);
        $isSuccess = ($responseCode == '00');
        
        // Cập nhật database
        if ($isValidSignature) {
            try {
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
                    } else {
                        // Thanh toán thất bại
                        $stmt = $pdo->prepare("UPDATE payments SET status = 'failed', updated_at = NOW() WHERE order_id = ? AND payment_method = 'VNPAY'");
                        $stmt->execute([$orderId]);
                    }
                }
            } catch (Exception $e) {
                error_log("Database error in return: " . $e->getMessage());
            }
        }
        ?>
        
        <div class="container">
            <div class="payment-result <?php echo $isValidSignature && $isSuccess ? 'success' : ($isValidSignature ? 'error' : 'pending'); ?>">
                <div class="text-center">
                    <?php if ($isValidSignature && $isSuccess): ?>
                        <div class="result-icon text-success">✅</div>
                        <h2 class="text-success">Thanh toán thành công!</h2>
                    <?php elseif ($isValidSignature): ?>
                        <div class="result-icon text-danger">❌</div>
                        <h2 class="text-danger">Thanh toán thất bại</h2>
                    <?php else: ?>
                        <div class="result-icon text-warning">⚠️</div>
                        <h2 class="text-warning">Chữ ký không hợp lệ</h2>
                    <?php endif; ?>
                </div>
                
                <div class="row mt-4">
                    <div class="col-md-6">
                        <p><strong>Mã đơn hàng:</strong></p>
                        <p class="text-muted"><?php echo htmlspecialchars($orderId); ?></p>
                    </div>
                    <div class="col-md-6">
                        <p><strong>Số tiền:</strong></p>
                        <p class="text-muted"><?php echo number_format($amount, 0, ',', '.'); ?> VNĐ</p>
                    </div>
                </div>
                
                <div class="row">
                    <div class="col-md-6">
                        <p><strong>Nội dung:</strong></p>
                        <p class="text-muted"><?php echo htmlspecialchars($orderInfo); ?></p>
                    </div>
                    <div class="col-md-6">
                        <p><strong>Mã phản hồi:</strong></p>
                        <p class="text-muted"><?php echo htmlspecialchars($responseCode); ?></p>
                    </div>
                </div>
                
                <?php if ($isValidSignature && $isSuccess): ?>
                <div class="row">
                    <div class="col-md-6">
                        <p><strong>Mã giao dịch VNPAY:</strong></p>
                        <p class="text-muted"><?php echo htmlspecialchars($transactionNo); ?></p>
                    </div>
                    <div class="col-md-6">
                        <p><strong>Ngân hàng:</strong></p>
                        <p class="text-muted"><?php echo htmlspecialchars($bankCode); ?></p>
                    </div>
                </div>
                
                <div class="row">
                    <div class="col-12">
                        <p><strong>Thời gian thanh toán:</strong></p>
                        <p class="text-muted"><?php echo date('d/m/Y H:i:s', strtotime($payDate)); ?></p>
                    </div>
                </div>
                <?php endif; ?>
                
                <div class="text-center btn-back">
                    <button class="btn btn-primary" onclick="goBack()">Quay lại ứng dụng</button>
                    <button class="btn btn-secondary ms-2" onclick="closeWindow()">Đóng cửa sổ</button>
                </div>
            </div>
        </div>
        
        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
        <script>
            function goBack() {
                // Thử mở app Flutter nếu có
                if (window.flutter_inappwebview) {
                    window.flutter_inappwebview.callHandler('paymentResult', {
                        success: <?php echo $isValidSignature && $isSuccess ? 'true' : 'false'; ?>,
                        orderId: '<?php echo $orderId; ?>',
                        amount: <?php echo $amount; ?>,
                        transactionNo: '<?php echo $transactionNo; ?>'
                    });
                } else {
                    // Fallback: quay lại trang trước
                    window.history.back();
                }
            }
            
            function closeWindow() {
                window.close();
            }
            
            // Tự động redirect sau 10 giây
            setTimeout(function() {
                goBack();
            }, 10000);
        </script>
    </body>
</html>
