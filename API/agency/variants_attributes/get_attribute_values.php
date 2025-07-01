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

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $attributeId = $_GET['attribute_id'] ?? null;
    
    if (!$attributeId) {
        sendResponse(false, 'Attribute ID is required', null, 400);
        exit;
    }
    
    try {
        $stmt = $conn->prepare("
            SELECT av.id, av.value, av.attribute_id, a.name as attribute_name
            FROM attribute_values av
            JOIN attributes a ON av.attribute_id = a.id
            WHERE av.attribute_id = ?
            ORDER BY av.value
        ");
        $stmt->bind_param("i", $attributeId);
        $stmt->execute();
        $result = $stmt->get_result();
        
        $values = [];
        while ($row = $result->fetch_assoc()) {
            $values[] = [
                'id' => $row['id'],
                'value' => $row['value'],
                'attribute_id' => $row['attribute_id'],
                'attribute_name' => $row['attribute_name']
            ];
        }
        
        sendResponse(true, 'Attribute values retrieved successfully', $values);
        
    } catch (Exception $e) {
        sendResponse(false, 'Database error: ' . $e->getMessage(), null, 500);
    }
} else {
    sendResponse(false, 'Method not allowed', null, 405);
}
?> 