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

$attribute_id = isset($_GET['attribute_id']) ? (int)$_GET['attribute_id'] : null;
if (!$attribute_id) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Thiếu attribute_id"]);
    exit();
}
$sql = "SELECT id as value_id, value FROM attribute_values WHERE attribute_id = ? ORDER BY id";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $attribute_id);
$stmt->execute();
$result = $stmt->get_result();
$values = [];
while ($row = $result->fetch_assoc()) {
    $values[] = [
        'value_id' => (int)$row['value_id'],
        'value' => $row['value']
    ];
}
$stmt->close();
http_response_code(200);
echo json_encode([
    "success" => true,
    "values" => $values
]);
$conn->close(); 