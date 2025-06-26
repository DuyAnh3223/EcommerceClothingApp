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

$conn->begin_transaction();
try {
    // Xóa liên kết với sản phẩm trong bảng product_variant
    $stmt = $conn->prepare("DELETE FROM product_variant WHERE product_id = ? AND variant_id = ?");
    $stmt->bind_param("ii", $product_id, $variant_id);
    $stmt->execute();
    $stmt->close();

    // Kiểm tra xem variant này có được sử dụng bởi sản phẩm khác không
    $other_products_check = $conn->prepare("SELECT COUNT(*) as count FROM product_variant WHERE variant_id = ?");
    $other_products_check->bind_param("i", $variant_id);
    $other_products_check->execute();
    $other_products_result = $other_products_check->get_result();
    $other_products_count = $other_products_result->fetch_assoc()['count'];
    $other_products_check->close();

    // Nếu variant không được sử dụng bởi sản phẩm nào khác, xóa hoàn toàn
    if ($other_products_count == 0) {
        $delete_vav = $conn->prepare("DELETE FROM variant_attribute_values WHERE variant_id = ?");
        $delete_vav->bind_param("i", $variant_id);
        $delete_vav->execute();
        $delete_vav->close();
        $delete_variant_stmt = $conn->prepare("DELETE FROM variants WHERE id = ?");
        $delete_variant_stmt->bind_param("i", $variant_id);
        $delete_variant_stmt->execute();
        $delete_variant_stmt->close();
    }

    $conn->commit();
    http_response_code(200);
    echo json_encode(["success" => true, "message" => "Xóa biến thể thành công"]);
} catch (Exception $e) {
    $conn->rollback();
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Lỗi khi xóa biến thể: " . $e->getMessage()]);
}
$conn->close(); 