<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: PUT, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once __DIR__ . '/../../config/db_connect.php';

$data = json_decode(file_get_contents("php://input"), true);

$required = ['product_id', 'variant_id', 'sku', 'attribute_value_ids'];
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
$variant_id = (int)$data['variant_id'];
$sku = trim($data['sku']);
$attribute_value_ids = $data['attribute_value_ids'];
$price = isset($data['price']) ? (float)$data['price'] : null;
$stock = isset($data['stock']) ? (int)$data['stock'] : null;
$image_url = isset($data['image_url']) ? trim($data['image_url']) : null;
$status = isset($data['status']) ? trim($data['status']) : null;
$price_bacoin = $data['price_bacoin'] ?? null;

$conn->begin_transaction();
try {
    // Cập nhật SKU cho variant
    $update_variant = $conn->prepare("UPDATE variants SET sku = ? WHERE id = ?");
    $update_variant->bind_param("si", $sku, $variant_id);
    $update_variant->execute();
    $update_variant->close();

    // Xóa hết attribute_value cũ của variant
    $conn->query("DELETE FROM variant_attribute_values WHERE variant_id = $variant_id");
    // Thêm lại attribute_value mới
    $insert_attr = $conn->prepare("INSERT INTO variant_attribute_values (variant_id, attribute_value_id) VALUES (?, ?)");
    foreach ($attribute_value_ids as $avid) {
        $avid = (int)$avid;
        $insert_attr->bind_param("ii", $variant_id, $avid);
        $insert_attr->execute();
    }
    $insert_attr->close();

    // Cập nhật product_variant
    $fields = [];
    $params = [];
    $types = '';
    if ($price !== null) {
        $fields[] = 'price = ?';
        $params[] = $price;
        $types .= 'd';
    }
    if ($stock !== null) {
        $fields[] = 'stock = ?';
        $params[] = $stock;
        $types .= 'i';
    }
    if ($image_url !== null) {
        $fields[] = 'image_url = ?';
        $params[] = $image_url;
        $types .= 's';
    }
    if ($status !== null) {
        $fields[] = 'status = ?';
        $params[] = $status;
        $types .= 's';
    }
    if ($price_bacoin !== null) {
        $fields[] = 'price_bacoin = ?';
        $params[] = $price_bacoin;
        $types .= 'd';
    }
    if (!empty($fields)) {
        $params[] = $product_id;
        $params[] = $variant_id;
        $types .= 'ii';
        $sql = "UPDATE product_variant SET " . implode(", ", $fields) . " WHERE product_id = ? AND variant_id = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param($types, ...$params);
        $stmt->execute();
        $stmt->close();
    }
    $conn->commit();
    http_response_code(200);
    echo json_encode([
        "success" => true,
        "message" => "Cập nhật biến thể thành công"
    ]);
} catch (Exception $e) {
    $conn->rollback();
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Lỗi khi cập nhật biến thể: " . $e->getMessage()
    ]);
}
$conn->close(); 