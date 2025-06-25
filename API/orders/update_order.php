<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");
require_once '../config/db_connect.php';

$data = json_decode(file_get_contents("php://input"), true);

$order_id = $data['order_id'] ?? null;
$status = $data['status'] ?? null;

if (!$order_id || !$status) {
    echo json_encode(["success" => false, "message" => "Thiếu order_id hoặc status"]);
    exit();
}

$stmt = $conn->prepare("UPDATE orders SET status = ? WHERE id = ?");
$stmt->bind_param("si", $status, $order_id);

if ($stmt->execute()) {
    echo json_encode(["success" => true, "message" => "Cập nhật trạng thái đơn hàng thành công"]);
} else {
    echo json_encode(["success" => false, "message" => "Lỗi: " . $conn->error]);
}
$stmt->close();
$conn->close();
?>