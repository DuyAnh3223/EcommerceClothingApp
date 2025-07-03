<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

require_once '../config/db_connect.php';

$user_id = $_POST['user_id'];
$serial_number = $_POST['serial_number'];
$card_code = $_POST['card_code'];

// Kiểm tra thẻ hợp lệ, chưa dùng
$sql = "SELECT * FROM card WHERE serial_number = ? AND card_code = ? AND status = 'unused'";
$stmt = $conn->prepare($sql);
$stmt->bind_param("ss", $serial_number, $card_code);
$stmt->execute();
$result = $stmt->get_result();

if ($row = $result->fetch_assoc()) {
    $amount = $row['crypto_coin']; // Hiển thị số coin đã mua vào bảng user_coin_wallet

    // Cộng coin vào ví user
    $sql_wallet = "INSERT INTO user_coin_wallet (user_id, balance) VALUES (?, ?) 
                   ON DUPLICATE KEY UPDATE balance = balance + VALUES(balance)";
    $stmt_wallet = $conn->prepare($sql_wallet);
    $stmt_wallet->bind_param("id", $user_id, $amount);
    $stmt_wallet->execute();

    // Đánh dấu thẻ đã dùng
    $sql_update = "UPDATE card SET status = 'used' WHERE id = ?";
    $stmt_update = $conn->prepare($sql_update);
    $stmt_update->bind_param("i", $row['id']);
    $stmt_update->execute();

    // Lưu lịch sử nạp thẻ
    $sql_log = "INSERT INTO card_transaction (user_id, card_id) VALUES (?, ?)";
    $stmt_log = $conn->prepare($sql_log);
    $stmt_log->bind_param("ii", $user_id, $row['id']);
    $stmt_log->execute();

    echo json_encode(["success" => true, "amount" => $amount]);
} else {
    echo json_encode(["success" => false, "message" => "Thẻ không hợp lệ hoặc đã dùng!"]);
}
?>