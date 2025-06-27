<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Lấy tên file từ parameter
$filename = $_GET['file'] ?? '';

if (empty($filename)) {
    header("Access-Control-Allow-Origin: *");
    http_response_code(400);
    echo "File parameter is required";
    exit();
}

// Loại bỏ prefix 'uploads/' nếu có
if (strpos($filename, 'uploads/') === 0) {
    $filename = substr($filename, 8); // Loại bỏ 'uploads/'
}

// Đường dẫn đến file
$file_path = '../uploads/' . $filename;

// Kiểm tra file có tồn tại không
if (!file_exists($file_path)) {
    header("Access-Control-Allow-Origin: *");
    http_response_code(404);
    echo "File not found: $filename (Path: $file_path)";
    exit();
}

// Lấy thông tin file
$file_info = pathinfo($file_path);
$extension = strtolower($file_info['extension']);

// Set content type dựa trên extension
$content_types = [
    'jpg' => 'image/jpeg',
    'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'gif' => 'image/gif',
    'webp' => 'image/webp'
];

if (isset($content_types[$extension])) {
    header('Content-Type: ' . $content_types[$extension]);
} else {
    header('Content-Type: application/octet-stream');
}

// Set cache headers
header('Cache-Control: public, max-age=31536000');
header('Expires: ' . gmdate('D, d M Y H:i:s \G\M\T', time() + 31536000));

// Đọc và output file
readfile($file_path);
?> 