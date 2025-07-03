<?php
require_once '../config/db_connect.php';
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");

$sql = "SELECT * FROM bacoin_packages";
$result = $conn->query($sql);
$packages = [];
while ($row = $result->fetch_assoc()) {
    $packages[] = $row;
}
echo json_encode(['success' => true, 'data' => $packages]);
?>
