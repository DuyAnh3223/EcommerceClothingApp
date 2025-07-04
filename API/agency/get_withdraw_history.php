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

$sql = "SELECT id, amount, note, status, admin_note, reviewed_by, reviewed_at, created_at FROM withdraw_requests WHERE agency_id = ? ORDER BY created_at DESC";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $agency_id);
$stmt->execute();
$result = $stmt->get_result();
$history = [];
while ($row = $result->fetch_assoc()) {
    $history[] = $row;
}
$stmt->close();
$conn->close();

echo json_encode([
    "success" => true,
    "data" => $history
]); 