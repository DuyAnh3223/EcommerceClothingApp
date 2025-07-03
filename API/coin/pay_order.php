<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

require_once '../config/db_connect.php';

$user_id = $_POST['user_id'];
$order_id = $_POST['order_id'];
$amount = $_POST['amount']; // Số coin cần thanh toán

// Kiểm tra số dư
$sql = "SELECT balance FROM user_coin_wallet WHERE user_id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $user_id);
$stmt->execute();
$stmt->bind_result($balance);
$stmt->fetch();
$stmt->close();

if ($balance >= $amount) {
    // Trừ coin
    $sql_update = "UPDATE user_coin_wallet SET balance = balance - ? WHERE user_id = ?";
    $stmt_update = $conn->prepare($sql_update);
    $stmt_update->bind_param("di", $amount, $user_id);
    $stmt_update->execute();

    // Cập nhật trạng thái đơn hàng
    $sql_order = "UPDATE orders SET payment_method = 'COIN', status = 'confirmed' WHERE id = ?";
    $stmt_order = $conn->prepare($sql_order);
    $stmt_order->bind_param("i", $order_id);
    $stmt_order->execute();

    echo json_encode(["success" => true]);
} else {
    echo json_encode(["success" => false, "message" => "Số dư không đủ!"]);
}
?>