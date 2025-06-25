<?php
$host = "localhost";
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
