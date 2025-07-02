<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once __DIR__ . '/../../config/db_connect.php';

$data = json_decode(file_get_contents("php://input"), true);
if (empty($data['attribute_id']) || empty($data['value'])) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Thiếu attribute_id hoặc value"]);
    exit();
}
$attribute_id = (int)$data['attribute_id'];
$value = trim($data['value']);
// Kiểm tra trùng giá trị
$check_stmt = $conn->prepare("SELECT id FROM attribute_values WHERE attribute_id = ? AND value = ?");
$check_stmt->bind_param("is", $attribute_id, $value);
$check_stmt->execute();
$check_stmt->store_result();
if ($check_stmt->num_rows > 0) {
    http_response_code(409);
    echo json_encode(["success" => false, "message" => "Giá trị đã tồn tại cho thuộc tính này"]);
    $check_stmt->close();
    exit();
}
$check_stmt->close();
$stmt = $conn->prepare("INSERT INTO attribute_values (attribute_id, value) VALUES (?, ?)");
$stmt->bind_param("is", $attribute_id, $value);
if ($stmt->execute()) {
    http_response_code(200);
    echo json_encode(["success" => true, "value_id" => $conn->insert_id]);
} else {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Lỗi khi thêm giá trị: " . $conn->error]);
}
$stmt->close();
$conn->close(); 