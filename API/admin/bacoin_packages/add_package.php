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

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(405, 'Method not allowed', null);
    exit;
}

$input = json_decode(file_get_contents('php://input'), true);

// Validate input
$required_fields = ['package_name', 'price_vnd', 'bacoin_amount'];
foreach ($required_fields as $field) {
    if (!isset($input[$field]) || empty($input[$field])) {
        sendResponse(400, "Missing required field: $field", null);
        exit;
    }
}

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
    // Kiểm tra tên gói đã tồn tại chưa
    $stmt = $conn->prepare("SELECT id FROM bacoin_packages WHERE package_name = ?");
    $stmt->bind_param("s", $package_name);
    $stmt->execute();
    $result = $stmt->get_result();
    if ($result->fetch_assoc()) {
        sendResponse(400, 'Package name already exists', null);
        exit;
    }
    
    // Thêm gói mới
    $stmt = $conn->prepare("INSERT INTO bacoin_packages (package_name, price_vnd, bacoin_amount, description) VALUES (?, ?, ?, ?)");
    $stmt->bind_param("sdds", $package_name, $price_vnd, $bacoin_amount, $description);
    $stmt->execute();
    
    $package_id = $conn->insert_id;
    
    // Lấy thông tin gói vừa tạo
    $stmt = $conn->prepare("SELECT * FROM bacoin_packages WHERE id = ?");
    $stmt->bind_param("i", $package_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $new_package = $result->fetch_assoc();
    
    sendResponse(201, 'Package created successfully', $new_package);
} catch (Exception $e) {
    sendResponse(500, 'Database error: ' . $e->getMessage(), null);
}
?> 