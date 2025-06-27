<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: PUT, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../config/db_connect.php';

$data = json_decode(file_get_contents("php://input"), true);

if (empty($data['id'])) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Thiếu ID sản phẩm"
    ]);
    exit();
}

$product_id = (int)$data['id'];
$name = isset($data['name']) ? trim($data['name']) : null;
$description = isset($data['description']) ? trim($data['description']) : null;
$category = isset($data['category']) ? trim($data['category']) : null;
$gender_target = isset($data['gender_target']) ? trim($data['gender_target']) : null;
$main_image = isset($data['main_image']) ? trim($data['main_image']) : null;

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

// Build update query dynamically
$fields = [];
$params = [];
$types = '';
if ($name !== null) {
    $fields[] = 'name = ?';
    $params[] = $name;
    $types .= 's';
}
if ($description !== null) {
    $fields[] = 'description = ?';
    $params[] = $description;
    $types .= 's';
}
if ($category !== null) {
    $fields[] = 'category = ?';
    $params[] = $category;
    $types .= 's';
}
if ($gender_target !== null) {
    $fields[] = 'gender_target = ?';
    $params[] = $gender_target;
    $types .= 's';
}
if ($main_image !== null) {
    $fields[] = 'main_image = ?';
    $params[] = $main_image;
    $types .= 's';
}
if (empty($fields)) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Không có trường nào để cập nhật"
    ]);
    exit();
}
$params[] = $product_id;
$types .= 'i';
$sql = "UPDATE products SET " . implode(", ", $fields) . " WHERE id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param($types, ...$params);
if ($stmt->execute()) {
    http_response_code(200);
    echo json_encode([
        "success" => true,
        "message" => "Cập nhật sản phẩm thành công"
    ]);
} else {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Lỗi khi cập nhật sản phẩm: " . $conn->error
    ]);
}
$stmt->close();
$conn->close();
?> 