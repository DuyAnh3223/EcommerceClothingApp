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
require_once __DIR__ . '/../../utils/validate.php';

// Kiểm tra quyền admin
$user = authenticate();
if (!$user || $user['role'] !== 'admin') {
    sendResponse(403, 'Unauthorized', null);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'PUT') {
    sendResponse(405, 'Method not allowed', null);
    exit;
}

$input = json_decode(file_get_contents('php://input'), true);

// Validate input
$required_fields = ['id', 'package_name', 'price_vnd', 'bacoin_amount'];
foreach ($required_fields as $field) {
    if (!isset($input[$field]) || empty($input[$field])) {
        sendResponse(400, "Missing required field: $field", null);
        exit;
    }
}

$id = intval($input['id']);
$package_name = trim($input['package_name']);
$price_vnd = floatval($input['price_vnd']);
$bacoin_amount = floatval($input['bacoin_amount']);
$description = isset($input['description']) ? trim($input['description']) : '';

// Validate data
if ($price_vnd <= 0 || $bacoin_amount <= 0) {
    sendResponse(400, 'Price and BACoin amount must be greater than 0', null);
    exit;
}

try {
    // Kiểm tra gói có tồn tại không
    $stmt = $conn->prepare("SELECT id FROM bacoin_packages WHERE id = ?");
    $stmt->bind_param("i", $id);
    $stmt->execute();
    $result = $stmt->get_result();
    if (!$result->fetch_assoc()) {
        sendResponse(404, 'Package not found', null);
        exit;
    }
    
    // Kiểm tra tên gói đã tồn tại chưa (trừ gói hiện tại)
    $stmt = $conn->prepare("SELECT id FROM bacoin_packages WHERE package_name = ? AND id != ?");
    $stmt->bind_param("si", $package_name, $id);
    $stmt->execute();
    $result = $stmt->get_result();
    if ($result->fetch_assoc()) {
        sendResponse(400, 'Package name already exists', null);
        exit;
    }
    
    // Cập nhật gói
    $stmt = $conn->prepare("UPDATE bacoin_packages SET package_name = ?, price_vnd = ?, bacoin_amount = ?, description = ? WHERE id = ?");
    $stmt->bind_param("sddsi", $package_name, $price_vnd, $bacoin_amount, $description, $id);
    $stmt->execute();
    
    // Lấy thông tin gói đã cập nhật
    $stmt = $conn->prepare("SELECT * FROM bacoin_packages WHERE id = ?");
    $stmt->bind_param("i", $id);
    $stmt->execute();
    $result = $stmt->get_result();
    $updated_package = $result->fetch_assoc();
    
    sendResponse(200, 'Package updated successfully', $updated_package);
} catch (Exception $e) {
    sendResponse(500, 'Database error: ' . $e->getMessage(), null);
}
?> 