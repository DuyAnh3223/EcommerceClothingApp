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
$product_id = isset($data['id']) ? (int)$data['id'] : null;

if (!$product_id) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Thiếu ID sản phẩm"
    ]);
    exit();
}

// Check if product exists
$check_stmt = $conn->prepare("SELECT id FROM products WHERE id = ?");
$check_stmt->bind_param("i", $product_id);
$check_stmt->execute();
$result = $check_stmt->get_result();
if ($result->num_rows === 0) {
    http_response_code(404);
    echo json_encode([
        "success" => false,
        "message" => "Sản phẩm không tồn tại"
    ]);
    $check_stmt->close();
    exit();
}
$check_stmt->close();

$conn->begin_transaction();
try {
    $stmt = $conn->prepare("DELETE FROM products WHERE id = ?");
    $stmt->bind_param("i", $product_id);
    if ($stmt->execute()) {
        $conn->commit();
        http_response_code(200);
        echo json_encode([
            "success" => true,
            "message" => "Xóa sản phẩm thành công"
        ]);
    } else {
        throw new Exception("Lỗi khi xóa sản phẩm: " . $conn->error);
    }
    $stmt->close();
} catch (Exception $e) {
    $conn->rollback();
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => $e->getMessage()
    ]);
}
$conn->close();
?> 