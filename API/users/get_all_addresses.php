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

$sql = "SELECT id, user_id, address_line, city, province, postal_code, is_default, created_at FROM user_addresses ORDER BY user_id, is_default DESC, id ASC";
$result = $conn->query($sql);
$addresses = [];
while ($row = $result->fetch_assoc()) {
    $addresses[] = [
        'id' => (int)$row['id'],
        'user_id' => (int)$row['user_id'],
        'address_line' => $row['address_line'],
        'city' => $row['city'],
        'province' => $row['province'],
        'postal_code' => $row['postal_code'],
        'is_default' => (int)$row['is_default'],
        'created_at' => $row['created_at']
    ];
}
$conn->close();

http_response_code(200);
echo json_encode([
    "success" => true,
    "message" => "Lấy tất cả địa chỉ thành công",
    "data" => $addresses
]); 