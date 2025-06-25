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

$sql = "SELECT p.id, p.name, p.description, p.category, p.gender_target, p.created_at, p.updated_at,
               ppv.product_variant_id, ppv.price, ppv.stock, ppv.status, ppv.image_url,
               pv.color, pv.size, pv.material
        FROM products p
        LEFT JOIN product_product_variant ppv ON p.id = ppv.product_id
        LEFT JOIN product_variants pv ON ppv.product_variant_id = pv.id
        ORDER BY p.id, ppv.product_variant_id";

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
$current_product = null;

while ($row = $result->fetch_assoc()) {
    $product_id = (int)$row['id'];
    if ($current_product === null || $current_product['id'] != $product_id) {
        if ($current_product !== null) {
            $products[] = $current_product;
        }
        $current_product = [
            'id' => $product_id,
            'name' => $row['name'],
            'description' => $row['description'],
            'category' => $row['category'],
            'gender_target' => $row['gender_target'],
            'created_at' => $row['created_at'],
            'updated_at' => $row['updated_at'],
            'variants' => []
        ];
    }
    if ($row['product_variant_id'] !== null) {
        $current_product['variants'][] = [
            'id' => (int)$row['product_variant_id'],
            'color' => $row['color'],
            'size' => $row['size'],
            'material' => $row['material'],
            'price' => (float)$row['price'],
            'stock' => (int)$row['stock'],
            'status' => $row['status'],
            'image_url' => $row['image_url']
        ];
    }
}
if ($current_product !== null) {
    $products[] = $current_product;
}

http_response_code(200);
echo json_encode([
    "success" => true,
    "message" => "Lấy danh sách sản phẩm thành công",
    "data" => $products
]);
$conn->close();
?>