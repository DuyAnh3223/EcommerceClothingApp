<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../config/db_connect.php';

$sql = "SELECT id, name, description, category, gender_target, created_at, updated_at FROM products ORDER BY id";
$result = $conn->query($sql);
if (!$result) {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Lỗi: " . $conn->error
    ]);
    $conn->close();
    exit();
}

$products = [];
while ($row = $result->fetch_assoc()) {
    $product_id = (int)$row['id'];
    // Lấy variants động cho sản phẩm này
    $variant_sql = "SELECT v.id as variant_id, v.sku, pv.price, pv.stock, pv.status, pv.image_url
                    FROM product_variant pv
                    JOIN variants v ON pv.variant_id = v.id
                    WHERE pv.product_id = ?";
    $variant_stmt = $conn->prepare($variant_sql);
    $variant_stmt->bind_param("i", $product_id);
    $variant_stmt->execute();
    $variant_result = $variant_stmt->get_result();
    $variants = [];
    while ($vrow = $variant_result->fetch_assoc()) {
        $variant_id = (int)$vrow['variant_id'];
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
            'sku' => $vrow['sku'],
            'price' => (float)$vrow['price'],
            'stock' => (int)$vrow['stock'],
            'status' => $vrow['status'],
            'image_url' => $vrow['image_url'],
            'attribute_values' => $attribute_values
        ];
    }
    $variant_stmt->close();
    $products[] = [
        'id' => $product_id,
        'name' => $row['name'],
        'description' => $row['description'],
        'category' => $row['category'],
        'gender_target' => $row['gender_target'],
        'created_at' => $row['created_at'],
        'updated_at' => $row['updated_at'],
        'variants' => $variants
    ];
}

http_response_code(200);
echo json_encode([
    "success" => true,
    "message" => "Lấy danh sách sản phẩm thành công",
    "data" => $products
]);
$conn->close();
?>