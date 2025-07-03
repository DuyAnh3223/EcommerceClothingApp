<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");
require_once '../config/db_connect.php';

$agency_id = isset($_GET['agency_id']) ? (int)$_GET['agency_id'] : 0;
if (!$agency_id) {
    echo json_encode([
        "success" => false,
        "message" => "Thiếu agency_id"
    ]);
    exit();
}

$sql = "
SELECT o.id AS order_id, o.order_date, o.status, oi.product_id, oi.quantity, p.name AS product_name
FROM orders o
JOIN order_items oi ON o.id = oi.order_id
JOIN products p ON oi.product_id = p.id
WHERE p.created_by = ?
  AND p.is_agency_product = 1
  AND o.status = 'confirmed'
ORDER BY o.order_date DESC, o.id DESC
";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $agency_id);
$stmt->execute();
$result = $stmt->get_result();

$orders = [];
while ($row = $result->fetch_assoc()) {
    $orders[] = [
        'order_id' => $row['order_id'],
        'order_date' => $row['order_date'],
        'status' => $row['status'],
        'product_id' => $row['product_id'],
        'product_name' => $row['product_name'],
        'quantity' => $row['quantity'],
    ];
}
$stmt->close();
$conn->close();

echo json_encode([
    "success" => true,
    "data" => $orders
]); 