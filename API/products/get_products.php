<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../config/db_connect.php';

// Get products with their variants (dùng bảng trung gian)
$sql = "SELECT p.id, p.name, p.description, p.category, p.gender_target, p.created_at, p.updated_at,
               pv.id as variant_id, pv.color, pv.size, pv.material, pv.price, pv.stock, pv.image_url, pv.status
        FROM products p
        LEFT JOIN product_product_variant ppv ON p.id = ppv.product_id
        LEFT JOIN product_variants pv ON ppv.product_variant_id = pv.id
        ORDER BY p.id, pv.id";

$result = $conn->query($sql);

$products = [];
$current_product = null;

while ($row = $result->fetch_assoc()) {
    $product_id = (int)$row['id'];
    // If this is a new product
    if ($current_product === null || $current_product['id'] != $product_id) {
        if ($current_product !== null) {
            $products[] = $current_product;
        }
        $current_product = [
            'id' => (int)$row['id'],
            'name' => $row['name'],
            'description' => $row['description'],
            'category' => $row['category'],
            'gender_target' => $row['gender_target'],
            'created_at' => $row['created_at'],
            'updated_at' => $row['updated_at'],
            'variants' => []
        ];
    }
    // Add variant if exists
    if ($row['variant_id'] !== null) {
        $current_product['variants'][] = [
            'id' => (int)$row['variant_id'],
            'color' => $row['color'],
            'size' => $row['size'],
            'material' => $row['material'],
            'price' => (float)$row['price'],
            'stock' => (int)$row['stock'],
            'image_url' => $row['image_url'],
            'status' => $row['status']
        ];
    }
}
// Add the last product
if ($current_product !== null) {
    $products[] = $current_product;
}
echo json_encode([
    "success" => true,
    "message" => "Lấy danh sách sản phẩm thành công",
    "data" => $products
]);
$conn->close();
?>