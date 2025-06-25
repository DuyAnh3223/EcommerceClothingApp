<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../config/db_connect.php';

$data = json_decode(file_get_contents("php://input"), true);

if (!empty($data['username']) && !empty($data['password']) && !empty($data['email'])) {
    $ten = $data['username'];
    $matkhau = $data['password'];
    $sdt = $data['phone'] ?? '';
    $email = $data['email'];
    $role = $data['role'] ?? 'user'; // Default to 'user' if not provided

    $stmt = $conn->prepare("INSERT INTO users (username, password, phone, email, role) VALUES (?, ?, ?, ?, ?)");
    $stmt->bind_param("sssss", $ten, $matkhau, $sdt, $email, $role);

    if ($stmt->execute()) {
        echo json_encode(["success" => 200, "message" => "Thêm người dùng thành công"]);
    } else {
        echo json_encode(["success" => 500, "message" => "Lỗi: " . $conn->error]);
    }
    $stmt->close();
} else {
    echo json_encode(["success" => 400, "message" => "Thiếu dữ liệu"]);
} 
?> 