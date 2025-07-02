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
$value_id = isset($data['value_id']) ? (int)$data['value_id'] : null;
if (!$value_id) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Thiếu value_id"]);
    exit();
}
$conn->begin_transaction();
try {
    // Xóa liên kết variant_attribute_values
    $conn->query("DELETE FROM variant_attribute_values WHERE attribute_value_id = $value_id");
    // Xóa giá trị thuộc tính
    $stmt = $conn->prepare("DELETE FROM attribute_values WHERE id = ?");
    $stmt->bind_param("i", $value_id);
    $stmt->execute();
    $stmt->close();
    $conn->commit();
    http_response_code(200);
    echo json_encode(["success" => true, "message" => "Xóa giá trị thành công"]);
} catch (Exception $e) {
    $conn->rollback();
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Lỗi khi xóa giá trị: " . $e->getMessage()]);
}
$conn->close(); 