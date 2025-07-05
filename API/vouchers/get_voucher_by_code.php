<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once __DIR__ . '/../config/db_connect.php';
require_once __DIR__ . '/../utils/response.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    sendResponse(405, 'Method not allowed', null);
    exit;
}

if (!isset($_GET['voucher_code']) || empty($_GET['voucher_code'])) {
    sendResponse(400, 'Missing voucher code parameter', null);
    exit;
}

$voucher_code = trim($_GET['voucher_code']);

try {
    // Tìm voucher theo mã
    $stmt = $conn->prepare("SELECT * FROM vouchers WHERE voucher_code = ?");
    $stmt->bind_param("s", $voucher_code);
    $stmt->execute();
    $result = $stmt->get_result();
    $voucher = $result->fetch_assoc();
    
    if (!$voucher) {
        sendResponse(404, 'Voucher not found', null);
        exit;
    }
    
    sendResponse(200, 'Success', $voucher);
} catch (Exception $e) {
    sendResponse(500, 'Database error: ' . $e->getMessage(), null);
}
?> 