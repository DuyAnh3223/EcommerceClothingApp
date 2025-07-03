<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../config/db_connect.php';

$sql = "SELECT id, name FROM attributes ORDER BY id";
$result = $conn->query($sql);
$attributes = [];
while ($row = $result->fetch_assoc()) {
    $attributes[] = [
        'id' => (int)$row['id'],
        'name' => $row['name']
    ];
}
http_response_code(200);
echo json_encode([
    "success" => true,
    "attributes" => $attributes
]);
$conn->close(); 