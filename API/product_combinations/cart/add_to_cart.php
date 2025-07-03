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

// Nhận dữ liệu JSON
$input = json_decode(file_get_contents('php://input'), true);
$user_id = isset($input['user_id']) ? (int)$input['user_id'] : 0;
$product_id = isset($input['product_id']) ? (int)$input['product_id'] : 0;
$variant_id = isset($input['variant_id']) ? (int)$input['variant_id'] : 0;
$quantity = isset($input['quantity']) ? (int)$input['quantity'] : 1;

if (!$user_id || !$product_id || !$variant_id || $quantity < 1) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Thiếu thông tin đầu vào."
    ]);
    exit();
}

// Kiểm tra tồn kho
$stock_sql = "SELECT stock FROM product_variant WHERE product_id = ? AND variant_id = ?";
$stock_stmt = $conn->prepare($stock_sql);
$stock_stmt->bind_param("ii", $product_id, $variant_id);
$stock_stmt->execute();
$stock_result = $stock_stmt->get_result();
if ($stock_result->num_rows === 0) {
    http_response_code(404);
    echo json_encode([
        "success" => false,
        "message" => "Không tìm thấy sản phẩm hoặc biến thể."
    ]);
    exit();
}
$stock_row = $stock_result->fetch_assoc();
$current_stock = (int)$stock_row['stock'];
if ($current_stock < $quantity) {
    http_response_code(409);
    echo json_encode([
        "success" => false,
        "message" => "Sản phẩm đã hết hàng hoặc không đủ số lượng."
    ]);
    exit();
}

// Kiểm tra nếu đã có trong giỏ thì cộng dồn số lượng
$check_sql = "SELECT id, quantity FROM cart_items WHERE user_id = ? AND product_id = ? AND variant_id = ?";
$check_stmt = $conn->prepare($check_sql);
$check_stmt->bind_param("iii", $user_id, $product_id, $variant_id);
$check_stmt->execute();
$check_result = $check_stmt->get_result();
if ($check_result->num_rows > 0) {
    $row = $check_result->fetch_assoc();
    $new_quantity = $row['quantity'] + $quantity;
    if ($new_quantity > $current_stock) {
        http_response_code(409);
        echo json_encode([
            "success" => false,
            "message" => "Sản phẩm đã hết hàng hoặc không đủ số lượng."
        ]);
        exit();
    }
    $update_sql = "UPDATE cart_items SET quantity = ? WHERE id = ?";
    $update_stmt = $conn->prepare($update_sql);
    $update_stmt->bind_param("ii", $new_quantity, $row['id']);
    $update_stmt->execute();
    $update_stmt->close();
} else {
    $insert_sql = "INSERT INTO cart_items (user_id, product_id, variant_id, quantity) VALUES (?, ?, ?, ?)";
    $insert_stmt = $conn->prepare($insert_sql);
    $insert_stmt->bind_param("iiii", $user_id, $product_id, $variant_id, $quantity);
    $insert_stmt->execute();
    $insert_stmt->close();
}

$check_stmt->close();
$stock_stmt->close();
$conn->close();

http_response_code(200);
echo json_encode([
    "success" => true,
    "message" => "Sản phẩm đã được thêm vào giỏ hàng!"
]);
