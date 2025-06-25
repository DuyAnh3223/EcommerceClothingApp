<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");
require_once '../config/db_connect.php';

$data = json_decode(file_get_contents("php://input"), true);
$order_item_id = $data['order_item_id'] ?? null;
$quantity = $data['quantity'] ?? null;
$price = $data['price'] ?? null;

if (!$order_item_id || !$quantity || !$price) {
    echo json_encode(["success" => false, "message" => "Thiếu thông tin bắt buộc"]);
    exit();
}

$stmt = $conn->prepare("UPDATE order_items SET quantity = ?, price = ? WHERE id = ?");
$stmt->bind_param("idi", $quantity, $price, $order_item_id);
if ($stmt->execute()) {
    echo json_encode(["success" => true, "message" => "Cập nhật chi tiết đơn hàng thành công"]);
} else {
    echo json_encode(["success" => false, "message" => "Lỗi: " . $conn->error]);
}
$stmt->close();
$conn->close();
?> 