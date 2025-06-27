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
$user_id = isset($input['user_id']) ? (int)$input['user_id'] : 0;
$product_id = isset($input['product_id']) ? (int)$input['product_id'] : 0;
$variant_id = isset($input['variant_id']) ? (int)$input['variant_id'] : 0;
$quantity = isset($input['quantity']) ? (int)$input['quantity'] : 1;
$address_id = isset($input['address_id']) ? (int)$input['address_id'] : 0;
$payment_method = isset($input['payment_method']) ? $input['payment_method'] : 'COD';

if (!$user_id || !$product_id || !$variant_id || !$address_id || $quantity < 1) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Thiếu thông tin đầu vào."
    ]);
    exit();
}

// Lấy giá và kiểm tra tồn kho
$pv_sql = "SELECT price, stock FROM product_variant WHERE product_id = ? AND variant_id = ?";
$pv_stmt = $conn->prepare($pv_sql);
$pv_stmt->bind_param("ii", $product_id, $variant_id);
$pv_stmt->execute();
$pv_result = $pv_stmt->get_result();
if ($pv_result->num_rows === 0) {
    http_response_code(404);
    echo json_encode([
        "success" => false,
        "message" => "Không tìm thấy sản phẩm hoặc biến thể."
    ]);
    exit();
}
$pv_row = $pv_result->fetch_assoc();
$price = (float)$pv_row['price'];
$stock = (int)$pv_row['stock'];
if ($stock < $quantity) {
    http_response_code(409);
    echo json_encode([
        "success" => false,
        "message" => "Sản phẩm đã hết hàng hoặc không đủ số lượng."
    ]);
    exit();
}
$total_amount = $price * $quantity;

// Tạo đơn hàng
$order_sql = "INSERT INTO orders (user_id, address_id, total_amount, status) VALUES (?, ?, ?, 'pending')";
$order_stmt = $conn->prepare($order_sql);
$order_stmt->bind_param("iid", $user_id, $address_id, $total_amount);
$order_stmt->execute();
$order_id = $order_stmt->insert_id;
$order_stmt->close();

// Thêm order_items
$item_sql = "INSERT INTO order_items (order_id, product_id, variant_id, quantity, price) VALUES (?, ?, ?, ?, ?)";
$item_stmt = $conn->prepare($item_sql);
$item_stmt->bind_param("iiiid", $order_id, $product_id, $variant_id, $quantity, $price);
$item_stmt->execute();
$item_stmt->close();

// Trừ tồn kho
$update_stock_sql = "UPDATE product_variant SET stock = stock - ? WHERE product_id = ? AND variant_id = ?";
$update_stock_stmt = $conn->prepare($update_stock_sql);
$update_stock_stmt->bind_param("iii", $quantity, $product_id, $variant_id);
$update_stock_stmt->execute();
$update_stock_stmt->close();

// Thêm payment
$pay_sql = "INSERT INTO payments (order_id, payment_method, amount, status) VALUES (?, ?, ?, 'pending')";
$pay_stmt = $conn->prepare($pay_sql);
$pay_stmt->bind_param("isd", $order_id, $payment_method, $total_amount);
$pay_stmt->execute();
$pay_stmt->close();

$conn->close();

http_response_code(200);
echo json_encode([
    "success" => true,
    "message" => "Đặt hàng thành công!",
    "order_id" => $order_id
]); 