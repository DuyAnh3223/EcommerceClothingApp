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

$combination_id = isset($_GET['combination_id']) ? (int)$_GET['combination_id'] : 0;

if (!$combination_id) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Thiếu combination_id."
    ]);
    exit();
}

// Lấy thông tin chi tiết các sản phẩm trong combo
$sql = "SELECT pci.id, pci.product_id, pci.variant_id, pci.quantity, pci.price_in_combination,
               p.name as product_name, p.main_image as product_image, p.category as product_category,
               pv.price, pv.stock, pv.image_url as variant_image
        FROM product_combination_items pci
        JOIN products p ON pci.product_id = p.id
        LEFT JOIN product_variant pv ON pci.product_id = pv.product_id AND pci.variant_id = pv.variant_id
        WHERE pci.combination_id = ?";

$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $combination_id);
$stmt->execute();
$result = $stmt->get_result();

$items = [];
while ($row = $result->fetch_assoc()) {
    // Lấy thuộc tính của variant
    $attr_sql = "SELECT a.name as attribute_name, av.value
                 FROM variant_attribute_values vav
                 JOIN attribute_values av ON vav.attribute_value_id = av.id
                 JOIN attributes a ON av.attribute_id = a.id
                 WHERE vav.variant_id = ?";
    $attr_stmt = $conn->prepare($attr_sql);
    $attr_stmt->bind_param("i", $row['variant_id']);
    $attr_stmt->execute();
    $attr_result = $attr_stmt->get_result();
    $attributes = [];
    while ($arow = $attr_result->fetch_assoc()) {
        $attributes[$arow['attribute_name']] = $arow['value'];
    }
    $attr_stmt->close();
    
    $items[] = [
        'id' => (int)$row['id'],
        'product_id' => (int)$row['product_id'],
        'variant_id' => (int)$row['variant_id'],
        'quantity' => (int)$row['quantity'],
        'price_in_combination' => (float)$row['price_in_combination'],
        'product_name' => $row['product_name'],
        'product_image' => $row['product_image'],
        'product_category' => $row['product_category'],
        'price' => (float)$row['price'],
        'stock' => (int)$row['stock'],
        'variant_image' => $row['variant_image'],
        'attributes' => $attributes,
        'image_url' => !empty($row['variant_image']) ? $row['variant_image'] : $row['product_image']
    ];
}

$stmt->close();
$conn->close();

http_response_code(200);
echo json_encode([
    "success" => true,
    "message" => "Lấy thông tin combo thành công",
    "data" => $items
]);
?> 