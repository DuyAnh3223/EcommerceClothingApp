<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
$host = "127.0.0.1";
$username = "root";
$password = "";
$database = "clothing_appstore";

// Tạo kết nối
$conn = new mysqli($host, $username, $password, $database);

// Kiểm tra lỗi
if ($conn->connect_error) {
    die(json_encode(["success" => false, "message" => "Kết nối thất bại: " . $conn->connect_error]));
}
?> 