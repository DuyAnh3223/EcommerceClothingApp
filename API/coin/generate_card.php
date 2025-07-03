<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
require_once '../config/db_connect.php';

function randomString($length = 12) {
    $characters = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    $charactersLength = strlen($characters);
    $randomString = '';
    for ($i = 0; $i < $length; $i++) {
        $randomString .= $characters[rand(0, $charactersLength - 1)];
    }
    return $randomString;
}

$promotion_id = $_POST['promotion_id'];
$price = $_POST['price'];
$quantity = $_POST['quantity'];

$created = 0;
$tries = 0;
while ($created < $quantity && $tries < $quantity * 10) {
    $serial = randomString(12);
    $code = randomString(10);
    // Kiểm tra trùng serial_number hoặc card_code
    $check = $conn->prepare("SELECT id FROM card WHERE serial_number = ? OR card_code = ? LIMIT 1");
    $check->bind_param("ss", $serial, $code);
    $check->execute();
    $check->store_result();
    if ($check->num_rows == 0) {
        $sql = "INSERT INTO card (serial_number, card_code, promotion_id, price, status) VALUES (?, ?, ?, ?, 'unused')";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("ssid", $serial, $code, $promotion_id, $price);
        if ($stmt->execute()) {
            $created++;
        }
        $stmt->close();
    }
    $check->close();
    $tries++;
}

if ($created == $quantity) {
    echo json_encode(['success' => true, 'message' => 'Đã tạo đủ thẻ thành công!']);
} else {
    echo json_encode(['success' => false, 'message' => "Chỉ tạo được $created/$quantity thẻ (do trùng lặp)"]);
}
?> 