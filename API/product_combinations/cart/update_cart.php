<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../config/db_connect.php';

$input = json_decode(file_get_contents('php://input'), true);
$cart_item_id = isset($input['cart_item_id']) ? (int)$input['cart_item_id'] : 0;
$quantity = isset($input['quantity']) ? (int)$input['quantity'] : 0;

if (!$cart_item_id) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Thiếu cart_item_id."
    ]);
    exit();
}

if ($quantity < 0) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Số lượng không hợp lệ."
    ]);
    exit();
}

if ($quantity == 0) {
    // Xóa sản phẩm khỏi giỏ
    $del_sql = "DELETE FROM cart_items WHERE id = ?";
    $del_stmt = $conn->prepare($del_sql);
    $del_stmt->bind_param("i", $cart_item_id);
    $del_stmt->execute();
    $del_stmt->close();
    $conn->close();
    http_response_code(200);
    echo json_encode([
        "success" => true,
        "message" => "Đã xóa sản phẩm khỏi giỏ hàng."
    ]);
    exit();
}

// Kiểm tra tồn kho
$stock_sql = "SELECT pv.stock FROM cart_items ci JOIN product_variant pv ON ci.product_id = pv.product_id AND ci.variant_id = pv.variant_id WHERE ci.id = ?";
$stock_stmt = $conn->prepare($stock_sql);
$stock_stmt->bind_param("i", $cart_item_id);
$stock_stmt->execute();
$stock_result = $stock_stmt->get_result();
if ($stock_result->num_rows === 0) {
    http_response_code(404);
    echo json_encode([
        "success" => false,
        "message" => "Không tìm thấy sản phẩm trong giỏ hàng."
    ]);
    exit();
}
$stock_row = $stock_result->fetch_assoc();
$current_stock = (int)$stock_row['stock'];
if ($quantity > $current_stock) {
    http_response_code(409);
    echo json_encode([
        "success" => false,
        "message" => "Số lượng vượt quá tồn kho."
    ]);
    exit();
}

// Cập nhật số lượng
$update_sql = "UPDATE cart_items SET quantity = ? WHERE id = ?";
$update_stmt = $conn->prepare($update_sql);
$update_stmt->bind_param("ii", $quantity, $cart_item_id);
$update_stmt->execute();
$update_stmt->close();
$stock_stmt->close();
$conn->close();

http_response_code(200);
echo json_encode([
    "success" => true,
    "message" => "Cập nhật số lượng thành công."
]);
