<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../../config/db_connect.php';

// Nhận dữ liệu JSON
$input = json_decode(file_get_contents('php://input'), true);
$user_id = isset($input['user_id']) ? (int)$input['user_id'] : 0;
$combination_id = isset($input['combination_id']) ? (int)$input['combination_id'] : 0;
$quantity = isset($input['quantity']) ? (int)$input['quantity'] : 1;
$items = isset($input['items']) ? $input['items'] : [];

if (!$user_id || !$combination_id || $quantity < 1 || empty($items)) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Thiếu thông tin đầu vào."
    ]);
    exit();
}

// Kiểm tra combination có tồn tại và active không
$combination_sql = "SELECT id, name, description, image_url, discount_price, original_price, status FROM product_combinations WHERE id = ? AND status = 'active'";
$combination_stmt = $conn->prepare($combination_sql);
$combination_stmt->bind_param("i", $combination_id);
$combination_stmt->execute();
$combination_result = $combination_stmt->get_result();

if ($combination_result->num_rows === 0) {
    http_response_code(404);
    echo json_encode([
        "success" => false,
        "message" => "Không tìm thấy combination hoặc combination không active."
    ]);
    exit();
}

$combination = $combination_result->fetch_assoc();
$combination_stmt->close();

// Bắt đầu transaction
$conn->begin_transaction();

try {
    // Kiểm tra tồn kho cho tất cả items
    foreach ($items as $item) {
        $product_id = (int)$item['product_id'];
        $variant_id = (int)$item['variant_id'];
        $item_quantity = (int)$item['quantity'];
        $total_quantity = $item_quantity * $quantity; // Số lượng trong combo * số lượng combo

        // Kiểm tra tồn kho
        $stock_sql = "SELECT stock FROM product_variant WHERE product_id = ? AND variant_id = ?";
        $stock_stmt = $conn->prepare($stock_sql);
        $stock_stmt->bind_param("ii", $product_id, $variant_id);
        $stock_stmt->execute();
        $stock_result = $stock_stmt->get_result();

        if ($stock_result->num_rows === 0) {
            throw new Exception("Không tìm thấy sản phẩm hoặc biến thể.");
        }

        $stock_row = $stock_result->fetch_assoc();
        $current_stock = (int)$stock_row['stock'];

        if ($current_stock < $total_quantity) {
            throw new Exception("Sản phẩm đã hết hàng hoặc không đủ số lượng.");
        }

        $stock_stmt->close();
    }

    // Kiểm tra nếu đã có combo này trong giỏ hàng thì cộng dồn số lượng
    $check_sql = "SELECT id, quantity FROM cart_items WHERE user_id = ? AND combination_id = ?";
    $check_stmt = $conn->prepare($check_sql);
    $check_stmt->bind_param("ii", $user_id, $combination_id);
    $check_stmt->execute();
    $check_result = $check_stmt->get_result();

    if ($check_result->num_rows > 0) {
        // Đã có combo trong giỏ hàng, cập nhật số lượng
        $row = $check_result->fetch_assoc();
        $new_quantity = $row['quantity'] + $quantity;
        
        $update_sql = "UPDATE cart_items SET quantity = ? WHERE id = ?";
        $update_stmt = $conn->prepare($update_sql);
        $update_stmt->bind_param("ii", $new_quantity, $row['id']);
        $update_stmt->execute();
        $update_stmt->close();
    } else {
        // Chưa có combo trong giỏ hàng, thêm mới
        $insert_sql = "INSERT INTO cart_items (user_id, combination_id, quantity, combination_name, combination_image, combination_price, combination_items) VALUES (?, ?, ?, ?, ?, ?, ?)";
        $insert_stmt = $conn->prepare($insert_sql);
        $combination_price = $combination['discount_price'] ?? $combination['original_price'] ?? 0;
        $combination_items_json = json_encode($items);
        $insert_stmt->bind_param("iiissds", $user_id, $combination_id, $quantity, $combination['name'], $combination['image_url'], $combination_price, $combination_items_json);
        $insert_stmt->execute();
        $insert_stmt->close();
    }

    $check_stmt->close();

    // Commit transaction
    $conn->commit();

    http_response_code(200);
    echo json_encode([
        "success" => true,
        "message" => "Combo đã được thêm vào giỏ hàng!"
    ]);

} catch (Exception $e) {
    // Rollback transaction nếu có lỗi
    $conn->rollback();
    
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => $e->getMessage()
    ]);
}

$conn->close();
?> 