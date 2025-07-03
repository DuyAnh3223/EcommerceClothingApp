<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
require_once '../config/db_connect.php';

$sql = "SELECT id, name, original_price, converted_price FROM promotion";
$result = $conn->query($sql);
$promotions = [];
while ($row = $result->fetch_assoc()) {
    $promotions[] = $row;
}
echo json_encode(['success' => true, 'data' => $promotions]);
?> 