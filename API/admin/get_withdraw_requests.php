<?php

require_once __DIR__ . '/../config/db_connect.php';
require_once __DIR__ . '/../utils/response.php';


header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header('Content-Type: application/json');

$status = isset($_GET['status']) ? $_GET['status'] : null;

$sql = "SELECT wr.*, u.username as agency_username FROM withdraw_requests wr JOIN users u ON wr.agency_id = u.id";
$params = [];
if ($status) {
    $sql .= " WHERE wr.status = ?";
    $params[] = $status;
}
$sql .= " ORDER BY wr.created_at DESC";

$stmt = $conn->prepare($sql);
if (!empty($params)) {
    $stmt->bind_param(str_repeat('s', count($params)), ...$params);
}
$stmt->execute();
$result = $stmt->get_result();

$requests = [];
while ($row = $result->fetch_assoc()) {
    $requests[] = $row;
}

sendResponse(true, 'Withdraw requests fetched successfully', $requests); 