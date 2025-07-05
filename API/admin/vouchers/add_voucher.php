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
$required_fields = ['voucher_code', 'discount_amount', 'quantity', 'start_date', 'end_date'];
foreach ($required_fields as $field) {
    if (!isset($input[$field]) || empty($input[$field])) {
        sendResponse(400, "Missing required field: $field", null);
        exit;
    }
}

$voucher_code = trim($input['voucher_code']);
$discount_amount = floatval($input['discount_amount']);
$quantity = intval($input['quantity']);
$start_date = $input['start_date'];
$end_date = $input['end_date'];

// Validate data
if ($discount_amount <= 0) {
    sendResponse(400, 'Discount amount must be greater than 0', null);
    exit;
}

if ($quantity <= 0) {
    sendResponse(400, 'Quantity must be greater than 0', null);
    exit;
}

// Validate dates
$start_datetime = new DateTime($start_date);
$end_datetime = new DateTime($end_date);
if ($start_datetime >= $end_datetime) {
    sendResponse(400, 'End date must be after start date', null);
    exit;
}

try {
    // Kiểm tra mã voucher đã tồn tại chưa
    $stmt = $conn->prepare("SELECT id FROM vouchers WHERE voucher_code = ?");
    $stmt->bind_param("s", $voucher_code);
    $stmt->execute();
    $result = $stmt->get_result();
    if ($result->fetch_assoc()) {
        sendResponse(400, 'Voucher code already exists', null);
        exit;
    }
    
    // Thêm voucher mới
    $stmt = $conn->prepare("INSERT INTO vouchers (voucher_code, discount_amount, quantity, start_date, end_date) VALUES (?, ?, ?, ?, ?)");
    $stmt->bind_param("sdiss", $voucher_code, $discount_amount, $quantity, $start_date, $end_date);
    $stmt->execute();
    
    $voucher_id = $conn->insert_id;
    
    // Lấy thông tin voucher vừa tạo
    $stmt = $conn->prepare("SELECT * FROM vouchers WHERE id = ?");
    $stmt->bind_param("i", $voucher_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $new_voucher = $result->fetch_assoc();
    
    sendResponse(201, 'Voucher created successfully', $new_voucher);
} catch (Exception $e) {
    sendResponse(500, 'Database error: ' . $e->getMessage(), null);
}
?> 