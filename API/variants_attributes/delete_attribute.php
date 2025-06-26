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
$attribute_id = isset($data['attribute_id']) ? (int)$data['attribute_id'] : null;
if (!$attribute_id) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Thiếu attribute_id"]);
    exit();
}
$conn->begin_transaction();
try {
    // Lấy tất cả value_id của thuộc tính này
    $value_ids = [];
    $result = $conn->query("SELECT id FROM attribute_values WHERE attribute_id = $attribute_id");
    while ($row = $result->fetch_assoc()) {
        $value_ids[] = (int)$row['id'];
    }
    // Xóa liên kết variant_attribute_values
    if (!empty($value_ids)) {
        $in = implode(',', $value_ids);
        $conn->query("DELETE FROM variant_attribute_values WHERE attribute_value_id IN ($in)");
    }
    // Xóa giá trị thuộc tính
    $conn->query("DELETE FROM attribute_values WHERE attribute_id = $attribute_id");
    // Xóa thuộc tính
    $stmt = $conn->prepare("DELETE FROM attributes WHERE id = ?");
    $stmt->bind_param("i", $attribute_id);
    $stmt->execute();
    $stmt->close();
    $conn->commit();
    http_response_code(200);
    echo json_encode(["success" => true, "message" => "Xóa thuộc tính thành công"]);
} catch (Exception $e) {
    $conn->rollback();
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Lỗi khi xóa thuộc tính: " . $e->getMessage()]);
}
$conn->close(); 