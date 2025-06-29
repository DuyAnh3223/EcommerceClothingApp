<?php
// Test file để kiểm tra URL return VNPAY
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

echo json_encode([
    "status" => "success",
    "message" => "VNPAY Return URL is accessible",
    "url" => "http://127.0.0.1/EcommerceClothingApp/API/vnpay_php/vnpay_return.php",
    "timestamp" => date('Y-m-d H:i:s'),
    "server_info" => [
        "php_version" => PHP_VERSION,
        "server_software" => $_SERVER['SERVER_SOFTWARE'] ?? 'Unknown',
        "request_method" => $_SERVER['REQUEST_METHOD'],
        "remote_addr" => $_SERVER['REMOTE_ADDR'] ?? 'Unknown'
    ]
]);
?> 