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

// Lấy available_balance và fee rate
$sql = "SELECT available_balance, total_fee, total_sales FROM withdraw_agency WHERE agency_id = ?";
$stmt2 = $conn->prepare($sql);
$stmt2->bind_param("i", $agency_id);
$stmt2->execute();
$result = $stmt2->get_result();
$row = $result->fetch_assoc();
$stmt2->close();
if (!$row) {
    echo json_encode([
        "success" => false,
        "message" => "Không tìm thấy thông tin agency."
    ]);
    exit();
}
$available_balance = (float)$row['available_balance'];
$total_sales = (float)$row['total_sales'];
$fee_rate = 0.2; // 20%
// Tính phí cho số tiền rút
$fee = $amount * $fee_rate;
$real_amount = $amount - $fee;
if ($amount > $available_balance) {
    echo json_encode([
        "success" => false,
        "message" => "Số tiền rút vượt quá số dư khả dụng!"
    ]);
    exit();
}
if ($real_amount <= 0) {
    echo json_encode([
        "success" => false,
        "message" => "Số tiền rút sau khi trừ phí phải lớn hơn 0!"
    ]);
    exit();
}
// Gửi yêu cầu rút tiền
$stmt = $conn->prepare("INSERT INTO withdraw_requests (agency_id, amount, note, status) VALUES (?, ?, ?, 'pending')");
$stmt->bind_param("ids", $agency_id, $amount, $note);
$success = $stmt->execute();
$stmt->close();
$conn->close();
if ($success) {
    echo json_encode([
        "success" => true,
        "message" => "Gửi yêu cầu rút tiền thành công!",
        "fee" => $fee,
        "real_amount" => $real_amount
    ]);
} else {
    echo json_encode([
        "success" => false,
        "message" => "Lỗi khi gửi yêu cầu rút tiền."
    ]);
} 