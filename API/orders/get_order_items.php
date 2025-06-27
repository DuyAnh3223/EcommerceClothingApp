<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");
require_once '../config/db_connect.php';

$order_id = $_GET['order_id'] ?? null;
if (!$order_id) {
    echo json_encode(["success" => false, "message" => "Thiếu order_id"]);
    exit();
}

$sql = "SELECT oi.id, oi.order_id, oi.product_id, oi.variant_id, oi.quantity, oi.price,
               COALESCE(NULLIF(pv.image_url, ''), p.main_image) as image_url,
               p.name as product_name
        FROM order_items oi
        JOIN product_variant pv ON oi.product_id = pv.product_id AND oi.variant_id = pv.variant_id
        JOIN products p ON oi.product_id = p.id
        WHERE oi.order_id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $order_id);
$stmt->execute();
$result = $stmt->get_result();

$items = [];
while ($row = $result->fetch_assoc()) {
    // Lấy thuộc tính variant
    $variant_attrs = [];
    $sql_attr = "SELECT av.value, a.name
                 FROM variant_attribute_values vav
                 JOIN attribute_values av ON vav.attribute_value_id = av.id
                 JOIN attributes a ON av.attribute_id = a.id
                 WHERE vav.variant_id = ?";
    $stmt_attr = $conn->prepare($sql_attr);
    $stmt_attr->bind_param("i", $row['variant_id']);
    $stmt_attr->execute();
    $result_attr = $stmt_attr->get_result();
    while ($attr = $result_attr->fetch_assoc()) {
        $variant_attrs[] = $attr['name'] . ': ' . $attr['value'];
    }
    $stmt_attr->close();
    $variant_str = implode(', ', $variant_attrs);

    $items[] = [
        "id" => (int)$row['id'],
        "order_id" => (int)$row['order_id'],
        "product_id" => (int)$row['product_id'],
        "variant_id" => (int)$row['variant_id'],
        "quantity" => (int)$row['quantity'],
        "price" => (float)$row['price'],
        "image_url" => $row['image_url'],
        "product_name" => $row['product_name'],
        "variant" => $variant_str
    ];
}
$stmt->close();

echo json_encode([
    "success" => true,
    "data" => $items
]);
$conn->close();
?> 