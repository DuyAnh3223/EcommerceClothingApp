<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../config/db_connect.php';

$cart_item_id = 0;
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    $cart_item_id = isset($input['cart_item_id']) ? (int)$input['cart_item_id'] : 0;
} else if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $cart_item_id = isset($_GET['cart_item_id']) ? (int)$_GET['cart_item_id'] : 0;
}

if (!$cart_item_id) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Thiếu cart_item_id."
    ]);
    exit();
}

$del_sql = "DELETE FROM cart_items WHERE id = ?";
$del_stmt = $conn->prepare($del_sql);
$del_stmt->bind_param("i", $cart_item_id);
$del_stmt->execute();
$affected = $del_stmt->affected_rows;
$del_stmt->close();
$conn->close();

if ($affected > 0) {
    http_response_code(200);
    echo json_encode([
        "success" => true,
        "message" => "Đã xóa sản phẩm khỏi giỏ hàng."
    ]);
} else {
    http_response_code(404);
    echo json_encode([
        "success" => false,
        "message" => "Không tìm thấy sản phẩm trong giỏ hàng."
    ]);
} 