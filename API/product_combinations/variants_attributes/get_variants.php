<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once __DIR__ . '/../../config/db_connect.php';

$product_id = isset($_GET['product_id']) ? (int)$_GET['product_id'] : null;
if (!$product_id) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Thiếu product_id"]);
    exit();
}

// Lấy tất cả variant của sản phẩm này
$sql = "SELECT v.id as variant_id, v.sku, pv.price, pv.stock, pv.image_url, pv.status
        FROM product_variant pv
        JOIN variants v ON pv.variant_id = v.id
        WHERE pv.product_id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $product_id);
$stmt->execute();
$result = $stmt->get_result();
$variants = [];
while ($row = $result->fetch_assoc()) {
    $variant_id = (int)$row['variant_id'];
    // Lấy các giá trị thuộc tính của variant này
    $attr_sql = "SELECT av.id as value_id, av.value, a.id as attribute_id, a.name as attribute_name
                 FROM variant_attribute_values vav
                 JOIN attribute_values av ON vav.attribute_value_id = av.id
                 JOIN attributes a ON av.attribute_id = a.id
                 WHERE vav.variant_id = ?";
    $attr_stmt = $conn->prepare($attr_sql);
    $attr_stmt->bind_param("i", $variant_id);
    $attr_stmt->execute();
    $attr_result = $attr_stmt->get_result();
    $attribute_values = [];
    while ($arow = $attr_result->fetch_assoc()) {
        $attribute_values[] = [
            'attribute_id' => (int)$arow['attribute_id'],
            'attribute_name' => $arow['attribute_name'],
            'value_id' => (int)$arow['value_id'],
            'value' => $arow['value']
        ];
    }
    $attr_stmt->close();
    $variants[] = [
        'variant_id' => $variant_id,
        'sku' => $row['sku'],
        'price' => (float)$row['price'],
        'stock' => (int)$row['stock'],
        'image_url' => $row['image_url'] ?? '',
        'status' => $row['status'],
        'attribute_values' => $attribute_values
    ];
}
$stmt->close();

// Lấy thông tin sản phẩm
$product_sql = "SELECT id, name, description, category, gender_target, main_image, status 
                FROM products WHERE id = ?";
$product_stmt = $conn->prepare($product_sql);
$product_stmt->bind_param("i", $product_id);
$product_stmt->execute();
$product_result = $product_stmt->get_result();
$product = $product_result->fetch_assoc();
$product_stmt->close();

// Fix null values in product data
if ($product) {
    $product['main_image'] = $product['main_image'] ?? '';
    $product['status'] = $product['status'] ?? '';
}

http_response_code(200);
echo json_encode([
    "success" => true,
    "variants" => $variants,
    "product" => $product,
    "total_variants" => count($variants)
]);
$conn->close(); 