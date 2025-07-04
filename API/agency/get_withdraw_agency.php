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

$sql = "SELECT total_sales, total_fee, personal_account_balance, available_balance FROM withdraw_agency WHERE agency_id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $agency_id);
$stmt->execute();
$result = $stmt->get_result();
$data = $result->fetch_assoc();
$stmt->close();

if ($data) {
    $conn->close();
    echo json_encode([
        "success" => true,
        "data" => $data
    ]);
} else {
    // Nếu chưa có bản ghi, tạo bản ghi mặc định
    $stmt2 = $conn->prepare("INSERT INTO withdraw_agency (agency_id, total_sales, total_fee, personal_account_balance) VALUES (?, 0, 0, 0)");
    $stmt2->bind_param("i", $agency_id);
    $stmt2->execute();
    $stmt2->close();
    $conn->close();
    echo json_encode([
        "success" => true,
        "data" => [
            "total_sales" => 0,
            "total_fee" => 0,
            "personal_account_balance" => 0,
            "available_balance" => 0
        ]
    ]);
} 