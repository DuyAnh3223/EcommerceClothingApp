<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

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

if (
    !empty($data['username']) &&
    !empty($data['password']) &&
    !empty($data['email']) &&
    !empty($data['phone']) &&
    !empty($data['gender']) &&
    !empty($data['role'])
) {
    $username = $data['username'];
    $password = password_hash($data['password'], PASSWORD_DEFAULT);
    $email = $data['email'];
    $phone = $data['phone'];
    $gender = $data['gender'];
    $role = $data['role'];
    $dob = !empty($data['dob']) ? $data['dob'] : null;

    // Validate gender and role
    $allowed_genders = ['male', 'female', 'other'];
    $allowed_roles = ['user', 'admin'];
    if (!in_array($gender, $allowed_genders) || !in_array($role, $allowed_roles)) {
        echo json_encode([
            "success" => false,
            "message" => "Giới tính hoặc vai trò không hợp lệ"
        ]);
        $conn->close();
        exit();
    }

    $stmt = $conn->prepare("INSERT INTO users (username, password, email, phone, gender, role, dob) VALUES (?, ?, ?, ?, ?, ?, ?)");
    $stmt->bind_param("sssssss", $username, $password, $email, $phone, $gender, $role, $dob);

    if ($stmt->execute()) {
        echo json_encode([
            "success" => true,
            "message" => "Thêm người dùng thành công"
        ]);
    } else {
        echo json_encode([
            "success" => false,
            "message" => "Lỗi: " . $stmt->error
        ]);
    }
    $stmt->close();
} else {
    echo json_encode([
        "success" => false,
        "message" => "Thiếu thông tin bắt buộc"
    ]);
}

$conn->close();
?> 