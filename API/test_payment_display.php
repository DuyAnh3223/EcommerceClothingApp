<?php
// Test script để kiểm tra hiển thị giá trị thanh toán theo phương thức
require_once 'config/db_connect.php';

echo "=== TEST PAYMENT DISPLAY API ===\n\n";

// Test API get_payments
$user_id = 4; // User ID để test
$url = "http://localhost/EcommerceClothingApp/API/payments/get_payments.php?user_id=$user_id&page=1&limit=10";

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);

$response = curl_exec($ch);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "HTTP Code: $http_code\n";
$result = json_decode($response, true);

if ($result['success']) {
    echo "✅ API hoạt động thành công!\n\n";
    
    $payments = $result['data']['payments'];
    echo "📋 Danh sách thanh toán:\n";
    
    foreach ($payments as $payment) {
        echo "\n--- Thanh toán #" . $payment['order_id'] . " ---\n";
        echo "ID: " . $payment['id'] . "\n";
        echo "Phương thức: " . $payment['payment_method'] . "\n";
        echo "Trạng thái: " . $payment['status'] . "\n";
        echo "Ngày đặt: " . $payment['order_date'] . "\n";
        echo "Ngày thanh toán: " . $payment['paid_at'] . "\n";
        echo "Mã giao dịch: " . $payment['transaction_code'] . "\n";
        
        // Hiển thị giá trị theo phương thức thanh toán
        echo "💰 Giá trị thanh toán:\n";
        echo "- Amount (VNĐ): " . number_format($payment['amount']) . " VNĐ\n";
        echo "- Amount BACoin: " . ($payment['amount_bacoin'] ? number_format($payment['amount_bacoin']) : 'NULL') . " BACoin\n";
        echo "- Display Amount: " . number_format($payment['display_amount']) . " " . $payment['display_currency'] . "\n";
        
        echo "📦 Tổng đơn hàng:\n";
        echo "- Total Amount (VNĐ): " . number_format($payment['order_total']) . " VNĐ\n";
        echo "- Total Amount BACoin: " . ($payment['order_total_bacoin'] ? number_format($payment['order_total_bacoin']) : 'NULL') . " BACoin\n";
        
        echo "🛍️ Sản phẩm:\n";
        foreach ($payment['products'] as $product) {
            echo "  - " . $product['name'] . "\n";
            echo "    Variant: " . $product['variant'] . "\n";
            echo "    Quantity: " . $product['quantity'] . "\n";
            echo "    Price (VNĐ): " . number_format($product['price']) . " VNĐ\n";
            echo "    Price BACoin: " . ($product['price_bacoin'] ? number_format($product['price_bacoin']) : 'NULL') . " BACoin\n";
            echo "    Display Price: " . number_format($product['display_price']) . " " . $product['display_currency'] . "\n";
        }
        
        echo "\n";
    }
    
    echo "🔍 Kiểm tra logic:\n";
    echo "- COD/VNPAY: display_amount = amount (VNĐ)\n";
    echo "- BACoin: display_amount = amount_bacoin (BACoin)\n";
    echo "- Currency hiển thị đúng theo phương thức thanh toán\n";
    
    $cod_count = 0;
    $vnpay_count = 0;
    $bacoin_count = 0;
    
    foreach ($payments as $payment) {
        switch ($payment['payment_method']) {
            case 'COD':
                $cod_count++;
                break;
            case 'VNPAY':
                $vnpay_count++;
                break;
            case 'BACoin':
                $bacoin_count++;
                break;
        }
    }
    
    echo "\n📊 Thống kê phương thức thanh toán:\n";
    echo "- COD: $cod_count đơn hàng\n";
    echo "- VNPAY: $vnpay_count đơn hàng\n";
    echo "- BACoin: $bacoin_count đơn hàng\n";
    
} else {
    echo "❌ Lỗi API: " . $result['message'] . "\n";
}

echo "\n=== KẾT THÚC TEST ===\n";
?> 