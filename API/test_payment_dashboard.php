<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json');

echo "=== TEST PAYMENT DASHBOARD API ===\n";

// Test the orders API
$url = 'http://127.0.0.1/EcommerceClothingApp/API/orders/get_orders.php';
$response = file_get_contents($url);

if ($response === false) {
    echo "❌ Không thể kết nối đến API\n";
    exit;
}

$data = json_decode($response, true);

if ($data === null) {
    echo "❌ Lỗi parse JSON\n";
    exit;
}

if ($data['success'] !== true) {
    echo "❌ API trả về lỗi: " . ($data['message'] ?? 'Unknown error') . "\n";
    exit;
}

echo "HTTP Code: 200 ✅ API hoạt động thành công!\n\n";

$orders = $data['data'];
echo "📋 Tổng số đơn hàng: " . count($orders) . "\n\n";

// Calculate totals
$totalVND = 0;
$totalBACoin = 0;
$paymentMethodTotals = [];

foreach ($orders as $order) {
    if (isset($order['payments']) && is_array($order['payments'])) {
        foreach ($order['payments'] as $payment) {
            if ($payment['status'] === 'paid') {
                $method = $payment['payment_method'];
                $amount = $payment['amount'] ?? 0;
                $amountBACoin = $payment['amount_bacoin'] ?? null;
                
                // Add to method totals
                if (!isset($paymentMethodTotals[$method])) {
                    $paymentMethodTotals[$method] = 0;
                }
                $paymentMethodTotals[$method] += $amount;
                
                // Add to currency totals
                if ($method === 'BACoin') {
                    $totalBACoin += $amountBACoin ?? 0;
                } else {
                    $totalVND += $amount;
                }
            }
        }
    }
}

echo "💰 Tổng quan thanh toán:\n";
echo "- Tổng VNĐ: " . number_format($totalVND) . " VNĐ\n";
echo "- Tổng BACoin: " . number_format($totalBACoin) . " BACoin\n";
echo "- Tổng đơn hàng: " . count($orders) . " đơn\n\n";

echo "📊 Chi tiết theo phương thức thanh toán:\n";
foreach ($paymentMethodTotals as $method => $total) {
    echo "- $method: " . number_format($total) . " VNĐ\n";
}

echo "\n🔍 Kiểm tra dữ liệu payments:\n";
$paymentCount = 0;
$bacoinPaymentCount = 0;

foreach ($orders as $order) {
    if (isset($order['payments']) && is_array($order['payments'])) {
        foreach ($order['payments'] as $payment) {
            $paymentCount++;
            if ($payment['payment_method'] === 'BACoin') {
                $bacoinPaymentCount++;
                echo "--- Thanh toán BACoin #$paymentCount ---\n";
                echo "Order ID: " . $payment['order_id'] . "\n";
                echo "Amount (VNĐ): " . number_format($payment['amount']) . " VNĐ\n";
                echo "Amount BACoin: " . number_format($payment['amount_bacoin'] ?? 0) . " BACoin\n";
                echo "Status: " . $payment['status'] . "\n";
                echo "Transaction Code: " . ($payment['transaction_code'] ?? 'N/A') . "\n\n";
            }
        }
    }
}

echo "📈 Thống kê:\n";
echo "- Tổng số thanh toán: $paymentCount\n";
echo "- Số thanh toán BACoin: $bacoinPaymentCount\n";

echo "\n=== KẾT THÚC TEST ===\n";
?> 