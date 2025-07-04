<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");
require_once '../config/db_connect.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode([
        "success" => false,
        "message" => "Chỉ hỗ trợ POST"
    ]);
    exit();
}

$agency_id = isset($_POST['agency_id']) ? (int)$_POST['agency_id'] : 0;
$amount = isset($_POST['amount']) ? (float)$_POST['amount'] : 0;
$note = isset($_POST['note']) ? trim($_POST['note']) : '';

if (!$agency_id || $amount <= 0) {
    echo json_encode([
        "success" => false,
        "message" => "Thiếu agency_id hoặc số tiền không hợp lệ"
    ]);
    exit();
}

$stmt = $conn->prepare("INSERT INTO withdraw_requests (agency_id, amount, note, status) VALUES (?, ?, ?, 'pending')");
$stmt->bind_param("ids", $agency_id, $amount, $note);
$success = $stmt->execute();
$stmt->close();
$conn->close();

if ($success) {
    echo json_encode([
        "success" => true,
        "message" => "Gửi yêu cầu rút tiền thành công!"
    ]);
} else {
    echo json_encode([
        "success" => false,
        "message" => "Lỗi khi gửi yêu cầu rút tiền."
    ]);
} 