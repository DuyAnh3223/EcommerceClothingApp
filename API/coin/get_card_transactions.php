<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

require_once '../config/db_connect.php';

$user_id = $_GET['user_id'] ?? null;
if (!$user_id) {
    echo json_encode(["success" => false, "message" => "Thiếu user_id!"]);
    exit;
}

$sql = "SELECT c.serial_number, c.card_code, c.crypto_coin, t.used_at FROM card_transaction t JOIN card c ON t.card_id = c.id WHERE t.user_id = ? ORDER BY t.used_at DESC";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $user_id);
$stmt->execute();
$result = $stmt->get_result();
$transactions = [];
while ($row = $result->fetch_assoc()) {
    $transactions[] = [
        "serial_number" => $row['serial_number'],
        "card_code" => $row['card_code'],
        "crypto_coin" => $row['crypto_coin'],
        "used_at" => $row['used_at']
    ];
}
$stmt->close();
echo json_encode(["success" => true, "transactions" => $transactions]); 