<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");
require_once '../config/db_connect.php';

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

$data = json_decode(file_get_contents("php://input"), true);
$order_id = $data['id'] ?? null;

if (!$order_id) {
    echo json_encode(["success" => false, "message" => "Thiếu order_id"]);
    exit();
}

// Xóa order_items trước
$stmt_items = $conn->prepare("DELETE FROM order_items WHERE order_id = ?");
$stmt_items->bind_param("i", $order_id);
$stmt_items->execute();
$stmt_items->close();

// Xóa đơn hàng
$stmt_order = $conn->prepare("DELETE FROM orders WHERE id = ?");
$stmt_order->bind_param("i", $order_id);
$success = $stmt_order->execute();
$stmt_order->close();

if ($success) {
    echo json_encode(["success" => true, "message" => "Xóa đơn hàng thành công"]);
} else {
    echo json_encode(["success" => false, "message" => "Lỗi: " . $conn->error]);
}
$conn->close();
?> 