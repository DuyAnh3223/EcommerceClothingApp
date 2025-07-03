<?php
require_once '../config/db_connect.php';
header('Content-Type: application/json');

$user_id = $_POST['user_id'] ?? 0;
$package_id = $_POST['package_id'] ?? 0;

if (!$user_id || !$package_id) {
    echo json_encode(['success' => false, 'message' => 'Thiếu user_id hoặc package_id']);
    exit;
}

// Lấy thông tin gói
$sql = "SELECT * FROM bacoin_packages WHERE id = $package_id";
$result = $conn->query($sql);
if (!$row = $result->fetch_assoc()) {
    echo json_encode(['success' => false, 'message' => 'Không tìm thấy gói']);
    exit;
}
$coin = $row['bacoin_amount'];
$price = $row['price_vnd'];

// Cộng coin cho user
$conn->query("UPDATE users SET balance = IFNULL(balance,0) + $coin WHERE id = $user_id");

// Lưu lịch sử giao dịch
$conn->query("INSERT INTO bacoin_transactions (user_id, amount, type, description) VALUES ($user_id, $coin, 'deposit', 'Mua gói BACoin #$package_id')");

echo json_encode(['success' => true, 'message' => 'Nạp coin thành công', 'amount' => $coin]);
?>
