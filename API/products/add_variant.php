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
$required = ['product_id', 'color', 'size', 'material', 'price', 'stock'];
$missing = [];
foreach ($required as $field) {
    if (!isset($data[$field]) || $data[$field] === '') {
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

$product_id = (int)$data['product_id'];
$color = trim($data['color']);
$size = trim($data['size']);
$material = trim($data['material']);
$price = (float)$data['price'];
$stock = (int)$data['stock'];
$image_url = isset($data['image_url']) ? trim($data['image_url']) : null;
$status = isset($data['status']) ? trim($data['status']) : 'active';

// Validate product_id exists
$check_stmt = $conn->prepare("SELECT id FROM products WHERE id = ?");
$check_stmt->bind_param("i", $product_id);
$check_stmt->execute();
$result = $check_stmt->get_result();
if ($result->num_rows === 0) {
    http_response_code(404);
    echo json_encode(["success" => false, "message" => "Sản phẩm không tồn tại"]);
    $check_stmt->close();
    exit();
}
$check_stmt->close();

// Kiểm tra biến thể đã tồn tại chưa (nếu chưa thì thêm mới)
$variant_stmt = $conn->prepare("SELECT id FROM product_variants WHERE color = ? AND size = ? AND material = ?");
$variant_stmt->bind_param("sss", $color, $size, $material);
$variant_stmt->execute();
$variant_result = $variant_stmt->get_result();
if ($variant_result->num_rows > 0) {
    $variant_row = $variant_result->fetch_assoc();
    $variant_id = $variant_row['id'];
} else {
    $insert_variant = $conn->prepare("INSERT INTO product_variants (color, size, material) VALUES (?, ?, ?)");
    $insert_variant->bind_param("sss", $color, $size, $material);
    $insert_variant->execute();
    $variant_id = $conn->insert_id;
    $insert_variant->close();
}
$variant_stmt->close();

// Kiểm tra tổ hợp product_id + variant_id đã tồn tại chưa
$link_check = $conn->prepare("SELECT * FROM product_product_variant WHERE product_id = ? AND product_variant_id = ?");
$link_check->bind_param("ii", $product_id, $variant_id);
$link_check->execute();
$link_check->store_result();
if ($link_check->num_rows > 0) {
    http_response_code(409);
    echo json_encode([
        "success" => false, 
        "message" => "Biến thể với màu '$color', kích thước '$size', chất liệu '$material' đã tồn tại cho sản phẩm này"
    ]);
    $link_check->close();
    exit();
}
$link_check->close();

// Thêm vào bảng trung gian
$link_stmt = $conn->prepare("INSERT INTO product_product_variant (product_id, product_variant_id, price, stock, image_url, status) VALUES (?, ?, ?, ?, ?, ?)");
$link_stmt->bind_param("iidiss", $product_id, $variant_id, $price, $stock, $image_url, $status);
if ($link_stmt->execute()) {
    http_response_code(200);
    echo json_encode([
        "success" => true,
        "message" => "Thêm biến thể thành công",
        "variant_id" => $variant_id,
        "product_id" => $product_id
    ]);
} else {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Lỗi khi thêm biến thể: " . $link_stmt->error]);
}
$link_stmt->close();
$conn->close();
?>
