<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");
require_once '../config/db_connect.php';

$order_id = $_GET['order_id'] ?? null;
if (!$order_id) {
    echo json_encode(["success" => false, "message" => "Thiếu order_id"]);
    exit();
}

$sql = "SELECT oi.id, oi.order_id, oi.product_variant_id, oi.quantity, oi.price,
               pv.color, pv.size, pv.material, pv.image_url,
               p.name as product_name
        FROM order_items oi
        JOIN product_variants pv ON oi.product_variant_id = pv.id
        JOIN products p ON pv.product_id = p.id
        WHERE oi.order_id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $order_id);
$stmt->execute();
$result = $stmt->get_result();

$items = [];
while ($row = $result->fetch_assoc()) {
    $items[] = [
        "id" => (int)$row['id'],
        "order_id" => (int)$row['order_id'],
        "product_variant_id" => (int)$row['product_variant_id'],
        "quantity" => (int)$row['quantity'],
        "price" => (float)$row['price'],
        "color" => $row['color'],
        "size" => $row['size'],
        "material" => $row['material'],
        "image_url" => $row['image_url'],
        "product_name" => $row['product_name']
    ];
}
$stmt->close();

echo json_encode([
    "success" => true,
    "items" => $items
]);
$conn->close();
?> 