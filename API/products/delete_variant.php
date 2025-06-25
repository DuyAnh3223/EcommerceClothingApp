<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../config/db_connect.php';

$data = json_decode(file_get_contents("php://input"), true);
$product_id = isset($data['product_id']) ? (int)$data['product_id'] : null;
$variant_id = isset($data['variant_id']) ? (int)$data['variant_id'] : null;
if (!$product_id || !$variant_id) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Thiếu product_id hoặc variant_id"]);
    exit();
}

// Bắt đầu transaction
$conn->begin_transaction();

try {
    // Check if variant exists
    $check_stmt = $conn->prepare("SELECT id FROM product_variants WHERE id = ?");
    $check_stmt->bind_param("i", $variant_id);
    $check_stmt->execute();
    $result = $check_stmt->get_result();
    if ($result->num_rows === 0) {
        http_response_code(404);
        echo json_encode([
            "success" => false,
            "message" => "Biến thể không tồn tại"
        ]);
        $check_stmt->close();
        exit();
    }
    $check_stmt->close();

    // Check if this variant is used in any orders
    $order_check_stmt = $conn->prepare("SELECT id FROM order_items WHERE product_variant_id = ?");
    $order_check_stmt->bind_param("i", $variant_id);
    $order_check_stmt->execute();
    $order_result = $order_check_stmt->get_result();
    if ($order_result->num_rows > 0) {
        http_response_code(409);
        echo json_encode([
            "success" => false,
            "message" => "Không thể xóa biến thể đã được sử dụng trong đơn hàng"
        ]);
        $order_check_stmt->close();
        exit();
    }
    $order_check_stmt->close();

    // Check if this variant is in any cart
    $cart_check_stmt = $conn->prepare("SELECT id FROM cart_items WHERE product_variant_id = ?");
    $cart_check_stmt->bind_param("i", $variant_id);
    $cart_check_stmt->execute();
    $cart_result = $cart_check_stmt->get_result();
    if ($cart_result->num_rows > 0) {
        http_response_code(409);
        echo json_encode([
            "success" => false,
            "message" => "Không thể xóa biến thể đang có trong giỏ hàng"
        ]);
        $cart_check_stmt->close();
        exit();
    }
    $cart_check_stmt->close();

    // Xóa liên kết với sản phẩm trong bảng product_product_variant
    $stmt = $conn->prepare("DELETE FROM product_product_variant WHERE product_id = ? AND product_variant_id = ?");
    $stmt->bind_param("ii", $product_id, $variant_id);
    $stmt->execute();
    $stmt->close();

    // Kiểm tra xem biến thể này có được sử dụng bởi sản phẩm khác không
    $other_products_check = $conn->prepare("SELECT COUNT(*) as count FROM product_product_variant WHERE product_variant_id = ?");
    $other_products_check->bind_param("i", $variant_id);
    $other_products_check->execute();
    $other_products_result = $other_products_check->get_result();
    $other_products_count = $other_products_result->fetch_assoc()['count'];
    $other_products_check->close();

    // Nếu biến thể không được sử dụng bởi sản phẩm nào khác, xóa hoàn toàn
    if ($other_products_count == 0) {
        $delete_variant_stmt = $conn->prepare("DELETE FROM product_variants WHERE id = ?");
        $delete_variant_stmt->bind_param("i", $variant_id);
        $delete_variant_stmt->execute();
        $delete_variant_stmt->close();
    }

    // Commit transaction
    $conn->commit();
    
    http_response_code(200);
    echo json_encode(["success" => true, "message" => "Xóa biến thể thành công"]);
    
} catch (Exception $e) {
    // Rollback transaction nếu có lỗi
    $conn->rollback();
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Lỗi khi xóa biến thể: " . $e->getMessage()]);
}

$conn->close();
