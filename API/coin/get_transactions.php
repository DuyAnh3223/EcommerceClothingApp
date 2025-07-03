<?php
require_once '../config/db_connect.php';
header('Content-Type: application/json');

$user_id = $_GET['user_id'] ?? 0;
if (!$user_id) {
    echo json_encode(['success' => false, 'message' => 'Thiếu user_id']);
    exit;
}

$sql = "SELECT * FROM bacoin_transactions WHERE user_id = $user_id ORDER BY created_at DESC";
$result = $conn->query($sql);
$transactions = [];
while ($row = $result->fetch_assoc()) {
    $transactions[] = $row;
}
echo json_encode(['success' => true, 'data' => $transactions]);
?>
