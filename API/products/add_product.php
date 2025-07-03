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

// Validate required fields
$required = ['name', 'category', 'gender_target'];
$missing = [];
foreach ($required as $field) {
    if (empty($data[$field])) {
        $missing[] = $field;
    }
}
if (!empty($missing)) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Thiếu trường bắt buộc: " . implode(", ", $missing)
    ]);
    exit();
}

$name = trim($data['name']);
$description = isset($data['description']) ? trim($data['description']) : null;
$category = trim($data['category']);
$gender_target = trim($data['gender_target']);
$main_image = isset($data['main_image']) ? trim($data['main_image']) : null;

// Nhận thêm các trường cho agency
$created_by = isset($data['created_by']) ? (int)$data['created_by'] : null;
$is_agency_product = isset($data['is_agency_product']) ? (int)$data['is_agency_product'] : 0;
$platform_fee_rate = isset($data['platform_fee_rate']) ? (float)$data['platform_fee_rate'] : 20.0;

// Nếu là sản phẩm agency thì bắt buộc phải có created_by và is_agency_product = 1
if ($is_agency_product === 1) {
    if (!$created_by) {
        http_response_code(400);
        echo json_encode([
            "success" => false,
            "message" => "Thiếu trường created_by cho sản phẩm agency"
        ]);
        exit();
    }
}

// Kiểm tra trùng sản phẩm
$check_stmt = $conn->prepare("SELECT id FROM products WHERE name = ? AND category = ? AND gender_target = ?");
$check_stmt->bind_param("sss", $name, $category, $gender_target);
$check_stmt->execute();
$check_stmt->store_result();
if ($check_stmt->num_rows > 0) {
    http_response_code(409);
    echo json_encode(["success" => false, "message" => "Sản phẩm đã tồn tại với cùng tên, danh mục và đối tượng"]);
    $check_stmt->close();
    exit();
}
$check_stmt->close();

// Insert product
$coin_price = $_POST['coin_price'] ?? null;
$stmt = $conn->prepare("INSERT INTO products (name, description, category, gender_target, main_image, created_by, is_agency_product, platform_fee_rate, coin_price) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)");
$stmt->bind_param("sssssiidf", $name, $description, $category, $gender_target, $main_image, $created_by, $is_agency_product, $platform_fee_rate, $coin_price);

if ($stmt->execute()) {
    http_response_code(200);
    echo json_encode([
        "success" => true,
        "message" => "Thêm sản phẩm thành công",
        "product_id" => $conn->insert_id
    ]);
} else {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Lỗi khi thêm sản phẩm: " . $conn->error
    ]);
}
$stmt->close();
$conn->close();
?> 