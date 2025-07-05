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

require_once __DIR__ . '/../../config/db_connect.php';
require_once __DIR__ . '/../../utils/auth.php';
require_once __DIR__ . '/../../utils/response.php';

// Kiểm tra quyền admin
$user = authenticate();
if (!$user || $user['role'] !== 'admin') {
    sendResponse(403, 'Unauthorized', null);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'DELETE') {
    sendResponse(405, 'Method not allowed', null);
    exit;
}

$input = json_decode(file_get_contents('php://input'), true);

if (!isset($input['id']) || empty($input['id'])) {
    sendResponse(400, 'Missing voucher ID', null);
    exit;
}

$id = intval($input['id']);

try {
    // Kiểm tra voucher có tồn tại không
    $stmt = $conn->prepare("SELECT id FROM vouchers WHERE id = ?");
    $stmt->bind_param("i", $id);
    $stmt->execute();
    $result = $stmt->get_result();
    if (!$result->fetch_assoc()) {
        sendResponse(404, 'Voucher not found', null);
        exit;
    }
    
    // Xóa voucher
    $stmt = $conn->prepare("DELETE FROM vouchers WHERE id = ?");
    $stmt->bind_param("i", $id);
    $stmt->execute();
    
    sendResponse(200, 'Voucher deleted successfully', null);
} catch (Exception $e) {
    sendResponse(500, 'Database error: ' . $e->getMessage(), null);
}
?> 