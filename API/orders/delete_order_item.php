<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");
require_once '../config/db_connect.php';

$data = json_decode(file_get_contents("php://input"), true);
$order_item_id = $data['order_item_id'] ?? null;

if (!$order_item_id) {
    echo json_encode(["success" => false, "message" => "Thiếu order_item_id"]);
    exit();
}

$stmt = $conn->prepare("DELETE FROM order_items WHERE id = ?");
$stmt->bind_param("i", $order_item_id);
if ($stmt->execute()) {
    echo json_encode(["success" => true, "message" => "Xóa chi tiết đơn hàng thành công"]);
} else {
    echo json_encode(["success" => false, "message" => "Lỗi: " . $conn->error]);
}
$stmt->close();
$conn->close();
?> 