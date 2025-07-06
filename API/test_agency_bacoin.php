<?php
// Test script để kiểm tra agency nhận BACoin
require_once 'config/db_connect.php';

echo "=== TEST AGENCY BACOIN RECEIPT ===\n\n";

// 1. Kiểm tra balance hiện tại của agency
echo "1. Kiểm tra balance hiện tại của agency...\n";
$agency_id = 9; // ID của agency
$agency_sql = "SELECT id, username, balance FROM users WHERE id = ? AND role = 'agency'";
$agency_stmt = $conn->prepare($agency_sql);
$agency_stmt->bind_param("i", $agency_id);
$agency_stmt->execute();
$agency_result = $agency_stmt->get_result();
$agency_data = $agency_result->fetch_assoc();
$agency_stmt->close();

if ($agency_data) {
    echo "📋 Thông tin agency:\n";
    echo "- ID: " . $agency_data['id'] . "\n";
    echo "- Username: " . $agency_data['username'] . "\n";
    echo "- Balance hiện tại: " . $agency_data['balance'] . " BACoin\n\n";
    $initial_balance = $agency_data['balance'];
} else {
    echo "❌ Không tìm thấy agency với ID $agency_id\n\n";
    exit;
}

// 2. Test đặt hàng với BACoin
echo "2. Test đặt hàng với BACoin...\n";

$test_data = [
    'user_id' => 4,
    'address_id' => 3,
    'payment_method' => 'BACoin',
    'cart_items' => [
        [
            'type' => 'product',
            'product_id' => 31, // Quần lửng (agency product)
            'variant_id' => 27,
            'quantity' => 1
        ]
    ]
];

$url = 'http://localhost/EcommerceClothingApp/API/orders/place_order_with_combinations.php';
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($test_data));
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

$response = curl_exec($ch);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "HTTP Code: $http_code\n";
echo "Response: $response\n";

$result = json_decode($response, true);
if ($result['success']) {
    $order_id = $result['order_id'];
    echo "✅ Đơn hàng được tạo thành công: #$order_id\n";
    echo "💰 Phân bổ BACoin:\n";
    echo "- Admin nhận: " . $result['bacoin_distribution']['admin_received'] . " BACoin\n";
    echo "- Agency nhận: " . $result['bacoin_distribution']['agency_received'] . " BACoin\n";
    echo "- Tổng phân bổ: " . $result['bacoin_distribution']['total_distributed'] . " BACoin\n\n";
} else {
    echo "❌ Lỗi tạo đơn hàng\n\n";
    exit;
}

// 3. Kiểm tra balance mới của agency
echo "3. Kiểm tra balance mới của agency...\n";
$agency_sql = "SELECT id, username, balance FROM users WHERE id = ? AND role = 'agency'";
$agency_stmt = $conn->prepare($agency_sql);
$agency_stmt->bind_param("i", $agency_id);
$agency_stmt->execute();
$agency_result = $agency_stmt->get_result();
$agency_data = $agency_result->fetch_assoc();
$agency_stmt->close();

if ($agency_data) {
    echo "📋 Thông tin agency sau khi mua hàng:\n";
    echo "- ID: " . $agency_data['id'] . "\n";
    echo "- Username: " . $agency_data['username'] . "\n";
    echo "- Balance mới: " . $agency_data['balance'] . " BACoin\n";
    
    $new_balance = $agency_data['balance'];
    $balance_change = $new_balance - $initial_balance;
    
    echo "- Thay đổi balance: " . $balance_change . " BACoin\n\n";
    
    if ($balance_change > 0) {
        echo "✅ Agency đã nhận BACoin thành công!\n";
    } else {
        echo "❌ Agency chưa nhận được BACoin!\n";
    }
} else {
    echo "❌ Không tìm thấy agency\n";
}

// 4. Kiểm tra giao dịch BACoin
echo "\n4. Kiểm tra giao dịch BACoin...\n";
$transaction_sql = "SELECT id, user_id, amount, type, description, created_at 
                   FROM bacoin_transactions 
                   WHERE user_id = ? AND type = 'receive' 
                   ORDER BY created_at DESC LIMIT 5";
$transaction_stmt = $conn->prepare($transaction_sql);
$transaction_stmt->bind_param("i", $agency_id);
$transaction_stmt->execute();
$transaction_result = $transaction_stmt->get_result();

echo "📋 Giao dịch BACoin gần đây của agency:\n";
while ($transaction = $transaction_result->fetch_assoc()) {
    echo "- ID: " . $transaction['id'] . "\n";
    echo "  Amount: " . $transaction['amount'] . " BACoin\n";
    echo "  Type: " . $transaction['type'] . "\n";
    echo "  Description: " . $transaction['description'] . "\n";
    echo "  Created: " . $transaction['created_at'] . "\n\n";
}
$transaction_stmt->close();

// 5. Kiểm tra order_items
echo "5. Kiểm tra order_items...\n";
$order_items_sql = "SELECT oi.id, oi.product_id, oi.variant_id, oi.quantity, oi.price, oi.price_bacoin, oi.platform_fee,
                           p.name as product_name, p.is_agency_product, p.created_by as agency_id
                   FROM order_items oi 
                   JOIN products p ON oi.product_id = p.id 
                   WHERE oi.order_id = ?";
$order_items_stmt = $conn->prepare($order_items_sql);
$order_items_stmt->bind_param("i", $order_id);
$order_items_stmt->execute();
$order_items_result = $order_items_stmt->get_result();

echo "📦 Order Items:\n";
while ($item = $order_items_result->fetch_assoc()) {
    echo "- Product: " . $item['product_name'] . "\n";
    echo "  Product ID: " . $item['product_id'] . "\n";
    echo "  Variant ID: " . $item['variant_id'] . "\n";
    echo "  Quantity: " . $item['quantity'] . "\n";
    echo "  Price (VNĐ): " . $item['price'] . "\n";
    echo "  Price BACoin: " . ($item['price_bacoin'] ?? 'NULL') . "\n";
    echo "  Platform Fee: " . $item['platform_fee'] . "\n";
    echo "  Is Agency Product: " . ($item['is_agency_product'] ? 'Yes' : 'No') . "\n";
    echo "  Agency ID: " . $item['agency_id'] . "\n\n";
}
$order_items_stmt->close();

echo "=== KẾT THÚC TEST ===\n";
?> 