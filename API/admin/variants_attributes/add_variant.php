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

// Validate required fields
$required = ['product_id', 'sku', 'attribute_value_ids', 'price', 'stock'];
$missing = [];
foreach ($required as $field) {
    if (!isset($data[$field]) || $data[$field] === '' || ($field === 'attribute_value_ids' && !is_array($data[$field]))) {
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
$sku = trim($data['sku']);
$attribute_value_ids = $data['attribute_value_ids'];
$price = (float)$data['price'];
$stock = (int)$data['stock'];
$image_url = isset($data['image_url']) ? trim($data['image_url']) : null;
$status = isset($data['status']) ? trim($data['status']) : 'active';
$price_bacoin = $data['price_bacoin'] ?? null;

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

$conn->begin_transaction();
try {
    // Kiểm tra variant với cùng attribute_value_ids đã tồn tại chưa
    $variant_id = null;
    $sku_check = $conn->prepare("SELECT id FROM variants WHERE sku = ?");
    $sku_check->bind_param("s", $sku);
    $sku_check->execute();
    $sku_result = $sku_check->get_result();
    if ($sku_result->num_rows > 0) {
        $row = $sku_result->fetch_assoc();
        $variant_id = $row['id'];
    }
    $sku_check->close();

    if ($variant_id === null) {
        // Tạo variant mới
        $insert_variant = $conn->prepare("INSERT INTO variants (sku) VALUES (?)");
        $insert_variant->bind_param("s", $sku);
        $insert_variant->execute();
        $variant_id = $conn->insert_id;
        $insert_variant->close();
        // Gán attribute_value cho variant
        $insert_attr = $conn->prepare("INSERT INTO variant_attribute_values (variant_id, attribute_value_id) VALUES (?, ?)");
        foreach ($attribute_value_ids as $avid) {
            $avid = (int)$avid;
            $insert_attr->bind_param("ii", $variant_id, $avid);
            $insert_attr->execute();
        }
        $insert_attr->close();
    }

    // Kiểm tra tổ hợp product_id + variant_id đã tồn tại chưa
    $link_check = $conn->prepare("SELECT * FROM product_variant WHERE product_id = ? AND variant_id = ?");
    $link_check->bind_param("ii", $product_id, $variant_id);
    $link_check->execute();
    $link_check->store_result();
    if ($link_check->num_rows > 0) {
        http_response_code(409);
        echo json_encode([
            "success" => false,
            "message" => "Biến thể này đã tồn tại cho sản phẩm này"
        ]);
        $link_check->close();
        $conn->rollback();
        exit();
    }
    $link_check->close();

    // Thêm vào bảng product_variant
    $link_stmt = $conn->prepare("INSERT INTO product_variant (product_id, variant_id, price, stock, image_url, status, price_bacoin) VALUES (?, ?, ?, ?, ?, ?, ?)");
    $link_stmt->bind_param("iiddsss", $product_id, $variant_id, $price, $stock, $image_url, $status, $price_bacoin);
    $link_stmt->execute();
    $link_stmt->close();

    $conn->commit();
    http_response_code(200);
    echo json_encode([
        "success" => true,
        "message" => "Thêm biến thể thành công",
        "variant_id" => $variant_id,
        "product_id" => $product_id
    ]);
} catch (Exception $e) {
    $conn->rollback();
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Lỗi khi thêm biến thể: " . $e->getMessage()]);
}
$conn->close(); 