<?php
require_once("../config/db_connect.php");

header('Content-Type: application/json');

// Test data
$user_id = 4; // Thay bằng user_id thực tế
$order_id = 110; // Thay bằng order_id thực tế

echo "=== TEST BACOIN PAYMENT ===\n";

// 1. Kiểm tra kết nối
if (!$conn) {
    echo "ERROR: Không có kết nối database\n";
    exit;
}

// 2. Kiểm tra user
$sql = "SELECT id, username, balance FROM users WHERE id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $user_id);
$stmt->execute();
$result = $stmt->get_result();
$user = $result->fetch_assoc();
$stmt->close();

if (!$user) {
    echo "ERROR: Không tìm thấy user ID: $user_id\n";
    exit;
}

echo "User: " . $user['username'] . "\n";
echo "Balance hiện tại: " . ($user['balance'] ?? 'NULL') . "\n";

// 3. Kiểm tra order
$sql = "SELECT id, total_amount FROM orders WHERE id = ? AND user_id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("ii", $order_id, $user_id);
$stmt->execute();
$result = $stmt->get_result();
$order = $result->fetch_assoc();
$stmt->close();

if (!$order) {
    echo "ERROR: Không tìm thấy order hoặc không đúng user\n";
    exit;
}

echo "Order ID: " . $order['id'] . "\n";
echo "Total amount: " . $order['total_amount'] . "\n";

// 4. Test update balance trực tiếp
$current_balance = $user['balance'] ?? 0;
$new_balance = $current_balance - $order['total_amount'];

echo "Balance sẽ trừ: " . $order['total_amount'] . "\n";
echo "Balance mới sẽ là: " . $new_balance . "\n";

if ($new_balance < 0) {
    echo "ERROR: Số dư không đủ\n";
    exit;
}

// 5. Thực hiện update
$sql = "UPDATE users SET balance = ? WHERE id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("di", $new_balance, $user_id);
$result = $stmt->execute();
$affected_rows = $stmt->affected_rows;
$stmt->close();

echo "Update result: " . ($result ? 'SUCCESS' : 'FAILED') . "\n";
echo "Affected rows: " . $affected_rows . "\n";

// 6. Kiểm tra balance sau update
$sql = "SELECT balance FROM users WHERE id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $user_id);
$stmt->execute();
$stmt->bind_result($updated_balance);
$stmt->fetch();
$stmt->close();

echo "Balance sau update: " . ($updated_balance ?? 'NULL') . "\n";

if ($result && $affected_rows > 0) {
    echo "SUCCESS: Test thành công!\n";
    echo json_encode([
        'success' => true,
        'old_balance' => $current_balance,
        'new_balance' => $updated_balance,
        'amount_deducted' => $order['total_amount']
    ]);
} else {
    echo "ERROR: Test thất bại!\n";
    echo json_encode([
        'success' => false,
        'error' => 'Không thể cập nhật balance'
    ]);
}
?> 