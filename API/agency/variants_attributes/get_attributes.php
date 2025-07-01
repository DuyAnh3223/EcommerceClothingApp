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

include_once '../../config/db_connect.php';
include_once '../../utils/response.php';
include_once '../../utils/auth.php';

// Check if user is agency
$user = authenticate();
if (!$user || $user['role'] !== 'agency') {
    sendResponse(false, 'Access denied. Agency role required.', null, 403);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    sendResponse(false, 'Method not allowed', null, 405);
    exit();
}

try {
    // Get all attributes created by admin or this agency
    $query = "
        SELECT 
            a.id,
            a.name,
            a.created_at,
            creator.username as created_by_name,
            a.created_by
        FROM attributes a
        LEFT JOIN users creator ON a.created_by = creator.id
        WHERE a.created_by = ? OR a.created_by IN (SELECT id FROM users WHERE role = 'admin')
        ORDER BY a.name ASC
    ";
    
    $stmt = $conn->prepare($query);
    $stmt->bind_param("i", $user['id']);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if (!$result) {
        sendResponse(false, 'Error retrieving attributes', null, 500);
        exit();
    }
    
    $attributes = [];
    while ($row = $result->fetch_assoc()) {
        // Get values for this attribute with creator information
        $value_query = "
            SELECT 
                av.id, 
                av.value, 
                av.created_by,
                creator.username as created_by_name
            FROM attribute_values av
            LEFT JOIN users creator ON av.created_by = creator.id
            WHERE av.attribute_id = ? 
            ORDER BY av.value ASC
        ";
        $stmt2 = $conn->prepare($value_query);
        $stmt2->bind_param("i", $row['id']);
        $stmt2->execute();
        $values_result = $stmt2->get_result();
        $values = [];
        while ($value = $values_result->fetch_assoc()) {
            $values[] = [
                'id' => $value['id'],
                'value' => $value['value'],
                'created_by' => $value['created_by'],
                'created_by_name' => $value['created_by_name']
            ];
        }
        $attributes[] = [
            'id' => $row['id'],
            'name' => $row['name'],
            'created_at' => $row['created_at'],
            'created_by' => $row['created_by'],
            'created_by_name' => $row['created_by_name'],
            'values' => $values
        ];
    }
    
    sendResponse(true, 'Attributes retrieved successfully', [
        'attributes' => $attributes
    ], 200);
    
} catch (Exception $e) {
    sendResponse(false, 'Error retrieving attributes: ' . $e->getMessage(), null, 500);
}

$conn->close(); 