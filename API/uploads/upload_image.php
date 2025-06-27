<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Kiểm tra method
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        "success" => false,
        "message" => "Chỉ chấp nhận method POST"
    ]);
    exit();
}

// Debug: Log request
error_log("Upload request received");

// Kiểm tra có file upload không
if (!isset($_FILES['image'])) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Không có file được upload"
    ]);
    exit();
}

if ($_FILES['image']['error'] !== UPLOAD_ERR_OK) {
    $error_messages = [
        UPLOAD_ERR_INI_SIZE => 'File vượt quá kích thước cho phép',
        UPLOAD_ERR_FORM_SIZE => 'File vượt quá kích thước form',
        UPLOAD_ERR_PARTIAL => 'File chỉ được upload một phần',
        UPLOAD_ERR_NO_FILE => 'Không có file nào được upload',
        UPLOAD_ERR_NO_TMP_DIR => 'Thiếu thư mục tạm',
        UPLOAD_ERR_CANT_WRITE => 'Không thể ghi file',
        UPLOAD_ERR_EXTENSION => 'Upload bị dừng bởi extension'
    ];
    
    $error_message = isset($error_messages[$_FILES['image']['error']]) 
        ? $error_messages[$_FILES['image']['error']] 
        : 'Lỗi upload không xác định';
    
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => $error_message,
        "error_code" => $_FILES['image']['error']
    ]);
    exit();
}

$file = $_FILES['image'];

// Debug: Log file info
error_log("File received: " . $file['name'] . ", size: " . $file['size'] . ", type: " . $file['type']);

// Kiểm tra loại file
$allowed_types = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'];
$file_type = mime_content_type($file['tmp_name']);

if (!in_array($file_type, $allowed_types)) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Chỉ chấp nhận file hình ảnh (JPEG, PNG, GIF, WebP). File type: " . $file_type
    ]);
    exit();
}

// Kiểm tra kích thước file (giới hạn 5MB)
$max_size = 5 * 1024 * 1024; // 5MB
if ($file['size'] > $max_size) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "File quá lớn. Kích thước tối đa là 5MB. File size: " . $file['size']
    ]);
    exit();
}

// Tạo tên file unique
$extension = pathinfo($file['name'], PATHINFO_EXTENSION);
$filename = uniqid() . '_' . time() . '.' . $extension;
$upload_path = '../uploads/' . $filename;

// Tạo thư mục nếu chưa có
if (!is_dir('../uploads/')) {
    if (!mkdir('../uploads/', 0777, true)) {
        http_response_code(500);
        echo json_encode([
            "success" => false,
            "message" => "Không thể tạo thư mục uploads"
        ]);
        exit();
    }
}

// Kiểm tra quyền ghi
if (!is_writable('../uploads/')) {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Không có quyền ghi vào thư mục uploads"
    ]);
    exit();
}

// Upload file
if (move_uploaded_file($file['tmp_name'], $upload_path)) {
    error_log("File uploaded successfully: " . $upload_path);
    http_response_code(200);
    echo json_encode([
        "success" => true,
        "message" => "Upload hình ảnh thành công",
        "filename" => $filename,
        "url" => $filename
    ]);
} else {
    error_log("Failed to move uploaded file from " . $file['tmp_name'] . " to " . $upload_path);
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Lỗi khi lưu file. Upload path: " . $upload_path
    ]);
}
?> 