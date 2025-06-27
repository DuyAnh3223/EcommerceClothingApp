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

$user_id = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
if (!$user_id) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Thiếu user_id."
    ]);
    exit();
}

$sql = "SELECT id, address_line, city, province, postal_code, is_default FROM user_addresses WHERE user_id = ? ORDER BY is_default DESC, id ASC";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $user_id);
$stmt->execute();
$result = $stmt->get_result();
$addresses = [];
while ($row = $result->fetch_assoc()) {
    $addresses[] = [
        'id' => (int)$row['id'],
        'address_line' => $row['address_line'],
        'city' => $row['city'],
        'province' => $row['province'],
        'postal_code' => $row['postal_code'],
        'is_default' => (int)$row['is_default']
    ];
}
$stmt->close();
$conn->close();

http_response_code(200);
echo json_encode([
    "success" => true,
    "message" => "Lấy danh sách địa chỉ thành công",
    "data" => $addresses
]); 