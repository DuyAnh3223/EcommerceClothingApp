<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Content-Type: application/json');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../../config/db_connect.php';
require_once '../../utils/response.php';
require_once '../../utils/auth.php';

// Kiểm tra authentication
$user = authenticate();
if (!$user) {
    sendResponse(false, 'Unauthorized', null, 401);
    exit;
}

// Kiểm tra role agency
if ($user['role'] !== 'agency') {
    sendResponse(false, 'Access denied. Agency role required.', null, 403);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'DELETE') {
    $input = json_decode(file_get_contents('php://input'), true);
    
    $attributeId = $input['attribute_id'] ?? null;
    
    if (!$attributeId) {
        sendResponse(false, 'Attribute ID is required', null, 400);
        exit;
    }
    
    // Kiểm tra thuộc tính được tạo bởi agency này
    $stmt = $conn->prepare("SELECT id FROM attributes WHERE id = ? AND created_by = ?");
    $stmt->bind_param("ii", $attributeId, $user['id']);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        sendResponse(false, 'Attribute not found or access denied. You can only delete attributes created by your agency.', null, 404);
        exit;
    }
    
    try {
        $conn->begin_transaction();
        
        // Xóa các giá trị thuộc tính (chỉ những giá trị do agency này tạo)
        $stmt = $conn->prepare("DELETE FROM attribute_values WHERE attribute_id = ? AND created_by = ?");
        $stmt->bind_param("ii", $attributeId, $user['id']);
        $stmt->execute();
        
        // Xóa liên kết với variants cho các giá trị đã xóa
        // (Có thể cần thêm logic phức tạp hơn nếu có variants sử dụng các giá trị này)
        
        // Xóa thuộc tính
        $stmt = $conn->prepare("DELETE FROM attributes WHERE id = ? AND created_by = ?");
        $stmt->bind_param("ii", $attributeId, $user['id']);
        $stmt->execute();
        
        if ($stmt->affected_rows === 0) {
            throw new Exception('Failed to delete attribute');
        }
        
        $conn->commit();
        sendResponse(true, 'Attribute deleted successfully');
        
    } catch (Exception $e) {
        $conn->rollback();
        sendResponse(false, 'Database error: ' . $e->getMessage(), null, 500);
    }
} else {
    sendResponse(false, 'Method not allowed', null, 405);
}
?> 