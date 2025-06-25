<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");
require_once '../config/db_connect.php';

$data = json_decode(file_get_contents("php://input"), true);

$user_id = $data['user_id'] ?? null;
$address_id = $data['address_id'] ?? null;
$total_amount = $data['total_amount'] ?? null;
$status = $data['status'] ?? 'pending';

if (!$user_id || !$address_id || !$total_amount) {
    echo json_encode(["success" => false, "message" => "Thiếu thông tin bắt buộc"]);
    exit();
}

$stmt = $conn->prepare("INSERT INTO orders (user_id, address_id, total_amount, status) VALUES (?, ?, ?, ?)");
$stmt->bind_param("iids", $user_id, $address_id, $total_amount, $status);

if ($stmt->execute()) {
    echo json_encode([
        "success" => true,
        "message" => "Tạo đơn hàng thành công",
        "order_id" => $conn->insert_id
    ]);
} else {
    echo json_encode(["success" => false, "message" => "Lỗi: " . $conn->error]);
}
$stmt->close();
$conn->close();
?>