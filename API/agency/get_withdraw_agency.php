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

$sql = "SELECT total_sales, total_fee, total_withdrawable, last_updated FROM withdraw_agency WHERE agency_id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $agency_id);
$stmt->execute();
$result = $stmt->get_result();
$data = $result->fetch_assoc();
$stmt->close();
$conn->close();

if ($data) {
    echo json_encode([
        "success" => true,
        "data" => $data
    ]);
} else {
    echo json_encode([
        "success" => false,
        "message" => "Không tìm thấy dữ liệu cho agency_id này"
    ]);
} 