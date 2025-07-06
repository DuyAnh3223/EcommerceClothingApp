<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json');

echo "=== TEST BACOIN DISTRIBUTION LOGIC ===\n";

// Test scenario: Agency product with 60,000 BACoin price and 20% platform fee
$product_price = 60000; // BACoin
$platform_fee_rate = 20; // 20%
$quantity = 1;

echo "📊 Test Scenario:\n";
echo "- Product Price: $product_price BACoin\n";
echo "- Platform Fee Rate: $platform_fee_rate%\n";
echo "- Quantity: $quantity\n\n";

// Calculate distribution
$total_amount = $product_price * $quantity;
$agency_amount = $total_amount / (1 + $platform_fee_rate / 100); // Giá gốc
$admin_amount = $total_amount - $agency_amount; // Phí sàn

echo "💰 Distribution Calculation:\n";
echo "- Total Amount: " . number_format($total_amount) . " BACoin\n";
echo "- Agency Amount (Giá gốc): " . number_format($agency_amount) . " BACoin\n";
echo("- Admin Amount (Phí sàn): " . number_format($admin_amount) . " BACoin\n");
echo "- Platform Fee: " . number_format($admin_amount) . " BACoin\n\n";

// Verify the calculation
$calculated_total = $agency_amount + $admin_amount;
echo "✅ Verification:\n";
echo "- Agency + Admin = " . number_format($agency_amount) . " + " . number_format($admin_amount) . " = " . number_format($calculated_total) . " BACoin\n";
echo "- Matches Total: " . ($calculated_total == $total_amount ? "YES" : "NO") . "\n\n";

// Check recent BACoin transactions
require_once 'config/db_connect.php';

echo "🔍 Recent BACoin Transactions:\n";
$sql = "SELECT bt.*, u.username, u.role 
        FROM bacoin_transactions bt 
        JOIN users u ON bt.user_id = u.id 
        WHERE bt.type IN ('spend', 'receive') 
        ORDER BY bt.created_at DESC 
        LIMIT 10";

$result = $conn->query($sql);

if ($result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $type_icon = $row['type'] === 'spend' ? '💸' : '💰';
        $role_icon = $row['role'] === 'agency' ? '🏢' : ($row['role'] === 'admin' ? '👑' : '👤');
        
        echo "$type_icon $role_icon {$row['username']} ({$row['role']}): " . number_format($row['amount']) . " BACoin - {$row['description']}\n";
    }
} else {
    echo "No recent transactions found.\n";
}

echo "\n📈 Current User Balances:\n";
$balance_sql = "SELECT username, role, balance FROM users WHERE role IN ('admin', 'agency', 'user') ORDER BY role, username";
$balance_result = $conn->query($balance_sql);

if ($balance_result->num_rows > 0) {
    while ($row = $balance_result->fetch_assoc()) {
        $role_icon = $row['role'] === 'agency' ? '🏢' : ($row['role'] === 'admin' ? '👑' : '👤');
        echo "$role_icon {$row['username']} ({$row['role']}): " . number_format($row['balance']) . " BACoin\n";
    }
} else {
    echo "No users found.\n";
}

echo "\n🔍 Analysis:\n";
echo "1. Agency products: Agency nhận giá gốc, Admin nhận phí sàn\n";
echo "2. Admin products: 100% cho admin\n";
echo "3. Platform fee được tính vào phí sàn, không phải phí nền tảng riêng\n";
echo "4. Tất cả đều được thanh toán bằng BACoin\n\n";

echo "=== KẾT THÚC TEST ===\n";

$conn->close();
?> 