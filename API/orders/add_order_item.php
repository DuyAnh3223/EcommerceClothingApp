<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");
require_once '../config/db_connect.php';

$data = json_decode(file_get_contents("php://input"), true);
$order_id = $data['order_id'] ?? null;
$product_variant_id = $data['product_variant_id'] ?? null;
$quantity = $data['quantity'] ?? null;
$price = $data['price'] ?? null;

if (!$order_id || !$product_variant_id || !$quantity || !$price) {
    echo json_encode(["success" => false, "message" => "Thiếu thông tin bắt buộc"]);
    exit();
}

$stmt = $conn->prepare("INSERT INTO order_items (order_id, product_variant_id, quantity, price) VALUES (?, ?, ?, ?)");
$stmt->bind_param("iiid", $order_id, $product_variant_id, $quantity, $price);
if ($stmt->execute()) {
    echo json_encode(["success" => true, "message" => "Thêm sản phẩm vào đơn hàng thành công", "order_item_id" => $conn->insert_id]);
} else {
    echo json_encode(["success" => false, "message" => "Lỗi: " . $conn->error]);
}
$stmt->close();
$conn->close();
?> 