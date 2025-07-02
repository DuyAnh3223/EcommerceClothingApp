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
$created_by = isset($_GET['created_by']) ? intval($_GET['created_by']) : null;

$sql = "SELECT * FROM attributes";
$params = [];
$types = "";

if ($created_by !== null) {
    $sql .= " WHERE created_by = ?";
    $params[] = $created_by;
    $types .= "i";
}

$stmt = $conn->prepare($sql);
if (!empty($params)) {
    $stmt->bind_param($types, ...$params);
}
$stmt->execute();
$result = $stmt->get_result();

$attributes = [];
while ($row = $result->fetch_assoc()) {
    $attributes[] = $row;
}

$stmt->close();
$conn->close();

http_response_code(200);
echo json_encode([
    "success" => true,
    "attributes" => $attributes
]);