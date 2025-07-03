<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");
require_once '../config/db_connect.php';

// Kiểm tra method
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

// Kiểm tra bảng withdraw_requests tồn tại chưa
$table_check = $conn->query("SHOW TABLES LIKE 'withdraw_requests'");
if ($table_check->num_rows == 0) {
    echo json_encode([
        "success" => false,
        "message" => "Bảng withdraw_requests chưa tồn tại.\n\nHãy tạo bảng bằng lệnh SQL sau:\n\nCREATE TABLE `withdraw_requests` (\n  `id` int(11) NOT NULL AUTO_INCREMENT,\n  `agency_id` int(11) NOT NULL,\n  `amount` decimal(15,2) NOT NULL,\n  `note` text,\n  `status` enum('pending','approved','rejected') DEFAULT 'pending',\n  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,\n  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,\n  PRIMARY KEY (`id`)\n);"
    ]);
    exit();
}

// Thêm yêu cầu rút tiền
$stmt = $conn->prepare("INSERT INTO withdraw_requests (agency_id, amount, note, status) VALUES (?, ?, ?, 'pending')");
$stmt->bind_param("ids", $agency_id, $amount, $note);
$success = $stmt->execute();
$stmt->close();
$conn->close();
//  avai - amount 
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