<?php
require_once '../config/db_connect.php';
header('Content-Type: application/json');

$user_id = $_GET['user_id'] ?? 0;
if (!$user_id) {
    echo json_encode(['success' => false, 'message' => 'Thiếu user_id']);
    exit;
}

$sql = "SELECT balance FROM users WHERE id = $user_id";
$result = $conn->query($sql);
if ($row = $result->fetch_assoc()) {
    echo json_encode(['success' => true, 'balance' => $row['balance'] ?? 0]);
} else {
    echo json_encode(['success' => false, 'message' => 'Không tìm thấy user']);
}
?>
