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
    
    $valueId = $input['value_id'] ?? null;
    
    if (!$valueId) {
        sendResponse(false, 'Value ID is required', null, 400);
        exit;
    }
    
    // Kiểm tra giá trị thuộc tính được tạo bởi agency này
    $stmt = $conn->prepare("SELECT id FROM attribute_values WHERE id = ? AND created_by = ?");
    $stmt->bind_param("ii", $valueId, $user['id']);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        sendResponse(false, 'Attribute value not found or access denied. You can only delete values created by your agency.', null, 404);
        exit;
    }
    
    try {
        $conn->begin_transaction();
        
        // Xóa liên kết với variants
        $stmt = $conn->prepare("DELETE FROM variant_attribute_values WHERE attribute_value_id = ?");
        $stmt->bind_param("i", $valueId);
        $stmt->execute();
        
        // Xóa giá trị thuộc tính
        $stmt = $conn->prepare("DELETE FROM attribute_values WHERE id = ? AND created_by = ?");
        $stmt->bind_param("ii", $valueId, $user['id']);
        $stmt->execute();
        
        if ($stmt->affected_rows === 0) {
            throw new Exception('Failed to delete attribute value');
        }
        
        $conn->commit();
        sendResponse(true, 'Attribute value deleted successfully');
        
    } catch (Exception $e) {
        $conn->rollback();
        sendResponse(false, 'Database error: ' . $e->getMessage(), null, 500);
    }
} else {
    sendResponse(false, 'Method not allowed', null, 405);
}
?> 