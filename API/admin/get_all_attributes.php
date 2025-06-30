<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Access-Control-Allow-Headers,Content-Type,Access-Control-Allow-Methods,Authorization,X-Requested-With');

include_once '../config/db_connect.php';
include_once '../utils/response.php';
include_once '../utils/auth.php';

// Check if user is admin
$user = authenticate();
if (!$user || $user['role'] !== 'admin') {
    sendResponse(403, 'Access denied. Admin role required.');
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    sendResponse(405, 'Method not allowed');
    exit();
}

try {
    // Get all attributes with their values (both admin and agency created)
    $query = "
        SELECT 
            a.id as attribute_id,
            a.name as attribute_name,
            a.created_by,
            u.username as created_by_name,
            u.role as created_by_role,
            av.id as value_id,
            av.value as attribute_value,
            av.created_by as value_created_by,
            uv.username as value_created_by_name,
            uv.role as value_created_by_role
        FROM attributes a
        LEFT JOIN attribute_values av ON a.id = av.attribute_id
        LEFT JOIN users u ON a.created_by = u.id
        LEFT JOIN users uv ON av.created_by = uv.id
        ORDER BY a.name, av.value
    ";
    
    $result = $conn->query($query);
    
    $attributes = [];
    while ($row = $result->fetch_assoc()) {
        $attr_name = $row['attribute_name'];
        
        if (!isset($attributes[$attr_name])) {
            $attributes[$attr_name] = [
                'id' => $row['attribute_id'],
                'name' => $attr_name,
                'created_by' => $row['created_by'],
                'created_by_name' => $row['created_by_name'],
                'created_by_role' => $row['created_by_role'],
                'values' => []
            ];
        }
        
        if ($row['value_id']) {
            $attributes[$attr_name]['values'][] = [
                'id' => $row['value_id'],
                'value' => $row['attribute_value'],
                'created_by' => $row['value_created_by'],
                'created_by_name' => $row['value_created_by_name'],
                'created_by_role' => $row['value_created_by_role']
            ];
        }
    }
    
    // Convert to indexed array
    $attributes_array = array_values($attributes);
    
    sendResponse(200, 'All attributes retrieved successfully', [
        'attributes' => $attributes_array
    ]);
    
} catch (Exception $e) {
    sendResponse(500, 'Error retrieving attributes: ' . $e->getMessage());
}

$conn->close();
?> 