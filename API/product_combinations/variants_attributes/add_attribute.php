<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../config/db_connect.php';

$data = json_decode(file_get_contents("php://input"), true);
if (empty($data['name'])) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Thiếu tên thuộc tính"]);
    exit();
}
$name = trim($data['name']);
// Kiểm tra trùng tên
$check_stmt = $conn->prepare("SELECT id FROM attributes WHERE name = ?");
$check_stmt->bind_param("s", $name);
$check_stmt->execute();
$check_stmt->store_result();
if ($check_stmt->num_rows > 0) {
    http_response_code(409);
    echo json_encode(["success" => false, "message" => "Thuộc tính đã tồn tại"]);
    $check_stmt->close();
    exit();
}
$check_stmt->close();
$stmt = $conn->prepare("INSERT INTO attributes (name) VALUES (?)");
$stmt->bind_param("s", $name);
if ($stmt->execute()) {
    http_response_code(200);
    echo json_encode(["success" => true, "attribute_id" => $conn->insert_id]);
} else {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Lỗi khi thêm thuộc tính: " . $conn->error]);
}
$stmt->close();
$conn->close(); 