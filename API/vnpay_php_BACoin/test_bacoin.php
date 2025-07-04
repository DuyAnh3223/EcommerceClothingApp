<?php
require_once("config.php");

header('Content-Type: application/json');

// Test data
$user_id = 4; // Thay bằng user_id thực tế
$order_id = 110; // Thay bằng order_id thực tế

echo "=== DEBUG BACOIN PAYMENT ===\n";

// 1. Kiểm tra kết nối database
if (!$conn) {
    echo json_encode(['error' => 'Không có kết nối database']);
    exit;
}

// 2. Kiểm tra user và balance hiện tại
$sql = "SELECT id, username, balance FROM users WHERE id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $user_id);
$stmt->execute();
$result = $stmt->get_result();
$user = $result->fetch_assoc();
$stmt->close();

if (!$user) {
    echo json_encode(['error' => 'Không tìm thấy user']);
    exit;
}

echo "User: " . $user['username'] . "\n";
echo "Balance hiện tại: " . ($user['balance'] ?? 'NULL') . "\n";

// 3. Kiểm tra order
$sql = "SELECT id, total_amount, status FROM orders WHERE id = ? AND user_id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("ii", $order_id, $user_id);
$stmt->execute();
$result = $stmt->get_result();
$order = $result->fetch_assoc();
$stmt->close();

if (!$order) {
    echo json_encode(['error' => 'Không tìm thấy order hoặc không đúng user']);
    exit;
}

echo "Order ID: " . $order['id'] . "\n";
echo "Total amount: " . $order['total_amount'] . "\n";
echo "Order status: " . $order['status'] . "\n";

// 4. Kiểm tra payment hiện tại
$sql = "SELECT id, status, payment_method, amount_bacoin FROM payments WHERE order_id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $order_id);
$stmt->execute();
$result = $stmt->get_result();
$payment = $result->fetch_assoc();
$stmt->close();

if ($payment) {
    echo "Payment status: " . $payment['status'] . "\n";
    echo "Payment method: " . $payment['payment_method'] . "\n";
    echo "Amount BACoin: " . ($payment['amount_bacoin'] ?? 'NULL') . "\n";
}

// 5. Test update balance
$current_balance = $user['balance'] ?? 0;
$new_balance = $current_balance - $order['total_amount'];

echo "Balance sẽ trừ: " . $order['total_amount'] . "\n";
echo "Balance mới sẽ là: " . $new_balance . "\n";

if ($new_balance < 0) {
    echo json_encode(['error' => 'Số dư không đủ']);
    exit;
}

// 6. Thực hiện update balance
$sql = "UPDATE users SET balance = ? WHERE id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("di", $new_balance, $user_id);
$result = $stmt->execute();
$affected_rows = $stmt->affected_rows;
$stmt->close();

echo "Update balance result: " . ($result ? 'SUCCESS' : 'FAILED') . "\n";
echo "Affected rows: " . $affected_rows . "\n";

// 7. Kiểm tra balance sau khi update
$sql = "SELECT balance FROM users WHERE id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $user_id);
$stmt->execute();
$stmt->bind_result($updated_balance);
$stmt->fetch();
$stmt->close();

echo "Balance sau khi update: " . ($updated_balance ?? 'NULL') . "\n";

if ($result && $affected_rows > 0) {
    echo json_encode([
        'success' => true,
        'message' => 'Test thành công',
        'old_balance' => $current_balance,
        'new_balance' => $updated_balance,
        'amount_deducted' => $order['total_amount']
    ]);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Test thất bại',
        'error' => 'Không thể cập nhật balance'
    ]);
}
?> 