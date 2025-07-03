<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

require_once '../config/db_connect.php';

$user_id = $_GET['user_id'];
$sql = "SELECT balance FROM user_coin_wallet WHERE user_id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $user_id);
$stmt->execute();
$stmt->bind_result($balance);
if ($stmt->fetch()) {
    echo json_encode(["success" => true, "balance" => $balance]);
} else {
    echo json_encode(["success" => true, "balance" => 0]);
}
?>