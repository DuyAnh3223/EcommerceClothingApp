<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Tạo thư mục uploads nếu chưa có
$upload_dir = '../uploads/';
if (!file_exists($upload_dir)) {
    mkdir($upload_dir, 0777, true);
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        "success" => false,
        "message" => "Chỉ hỗ trợ phương thức POST"
    ]);
    exit();
}

if (!isset($_FILES['image']) || $_FILES['image']['error'] !== UPLOAD_ERR_OK) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Không có file được upload hoặc lỗi upload"
    ]);
    exit();
}

$file = $_FILES['image'];
$allowed_types = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
$max_size = 5 * 1024 * 1024; // 5MB

// Kiểm tra loại file
if (!in_array($file['type'], $allowed_types)) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Chỉ chấp nhận file hình ảnh (JPEG, PNG, GIF, WebP)"
    ]);
    exit();
}

// Kiểm tra kích thước file
if ($file['size'] > $max_size) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "File quá lớn. Kích thước tối đa: 5MB"
    ]);
    exit();
}

// Tạo tên file unique
$extension = pathinfo($file['name'], PATHINFO_EXTENSION);
$filename = uniqid() . '_' . time() . '.' . $extension;
$filepath = $upload_dir . $filename;

// Upload file
if (move_uploaded_file($file['tmp_name'], $filepath)) {
    // Trả về URL hình ảnh
    $image_url = 'http://localhost/EcommerceClothingApp/API/uploads/' . $filename;
    
    http_response_code(200);
    echo json_encode([
        "success" => true,
        "message" => "Upload hình ảnh thành công",
        "image_url" => $image_url,
        "filename" => $filename
    ]);
} else {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Lỗi khi lưu file"
    ]);
} 