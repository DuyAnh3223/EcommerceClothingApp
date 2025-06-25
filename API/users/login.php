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

if (!empty($data['email']) && !empty($data['password'])) {
    $email = $data['email'];
    $password = $data['password'];

    $stmt = $conn->prepare("SELECT id, username, email, phone, gender, dob, role FROM users WHERE email = ? AND password = ?");
    $stmt->bind_param("ss", $email, $password);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        $user = $result->fetch_assoc();
        echo json_encode([
            "success" => true, 
            "message" => "Đăng nhập thành công",
            "user" => $user
        ]);
    } else {
        echo json_encode([
            "success" => false, 
            "message" => "Email hoặc mật khẩu không đúng"
        ]);
    }
    $stmt->close();
} else {
    echo json_encode([
        "success" => false, 
        "message" => "Vui lòng nhập đầy đủ thông tin"
    ]);
}

$conn->close();
?>
