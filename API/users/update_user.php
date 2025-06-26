<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../config/db_connect.php';

$data = json_decode(file_get_contents("php://input"), true);

if (!empty($data['id'])) {
    $id = $data['id'];
    $username = $data['username'] ?? null;
    $email = $data['email'] ?? null;
    $phone = $data['phone'] ?? null;
    $gender = $data['gender'] ?? null;
    $role = $data['role'] ?? null;
    $dob = $data['dob'] ?? null;
    $password = $data['password'] ?? null;

    $fields = [];
    $params = [];
    $types = '';

    if ($username) { $fields[] = 'username=?'; $params[] = $username; $types .= 's'; }
    if ($email) { $fields[] = 'email=?'; $params[] = $email; $types .= 's'; }
    if ($phone) { $fields[] = 'phone=?'; $params[] = $phone; $types .= 's'; }
    if ($gender) { $fields[] = 'gender=?'; $params[] = $gender; $types .= 's'; }
    if ($role) { $fields[] = 'role=?'; $params[] = $role; $types .= 's'; }
    if ($dob) { $fields[] = 'dob=?'; $params[] = $dob; $types .= 's'; }
    if ($password) { $fields[] = 'password=?'; $params[] = password_hash($password, PASSWORD_DEFAULT); $types .= 's'; }

    if (count($fields) > 0) {
        $sql = "UPDATE users SET ".implode(", ", $fields).", updated_at=NOW() WHERE id=?";
        $params[] = $id;
        $types .= 'i';
        $stmt = $conn->prepare($sql);
        $stmt->bind_param($types, ...$params);
        if ($stmt->execute()) {
            echo json_encode(["success" => true, "message" => "Cập nhật người dùng thành công"]);
        } else {
            echo json_encode(["success" => false, "message" => "Lỗi: ".$stmt->error]);
        }
        $stmt->close();
    } else {
        echo json_encode(["success" => false, "message" => "Không có trường nào để cập nhật"]);
    }
} else {
    echo json_encode(["success" => false, "message" => "Thiếu ID người dùng"]);
}

$conn->close();
