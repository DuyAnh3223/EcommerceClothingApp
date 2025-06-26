<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Logout endpoint - có thể thêm logic tracking hoặc cleanup session nếu cần
// Hiện tại chỉ trả về success vì logout chủ yếu xử lý ở client side

echo json_encode([
    "success" => true,
    "message" => "Đăng xuất thành công"
]);
?> 