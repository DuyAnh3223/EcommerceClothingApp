<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Access-Control-Allow-Headers,Content-Type,Access-Control-Allow-Methods,Authorization,X-Requested-With');

include_once '../config/db_connect.php';
include_once '../utils/response.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    sendResponse(false, 'Method not allowed', null, 405);
    exit();
}

try {
    // Get all attributes (admin and agency created)
    $query = "
        SELECT 
            a.id as attribute_id,
            a.name as attribute_name,
            a.created_by,
            u.username as created_by_name,
            av.id as value_id,
            av.value as attribute_value,
            av.created_by as value_created_by,
            uv.username as value_created_by_name
        FROM attributes a
        LEFT JOIN attribute_values av ON a.id = av.attribute_id
        LEFT JOIN users u ON a.created_by = u.id
        LEFT JOIN users uv ON av.created_by = uv.id
        ORDER BY a.name, av.value
    ";
    
    $stmt = $conn->prepare($query);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $attributes = [];
    while ($row = $result->fetch_assoc()) {
        $attr_name = $row['attribute_name'];
        
        if (!isset($attributes[$attr_name])) {
            $attributes[$attr_name] = [
                'id' => $row['attribute_id'],
                'name' => $attr_name,
                'created_by' => $row['created_by'],
                'created_by_name' => $row['created_by_name'],
                'values' => []
            ];
        }
        
        if ($row['value_id']) {
            $attributes[$attr_name]['values'][] = [
                'id' => $row['value_id'],
                'value' => $row['attribute_value'],
                'created_by' => $row['value_created_by'],
                'created_by_name' => $row['value_created_by_name']
            ];
        }
    }
    
    // Convert to indexed array
    $attributes_array = array_values($attributes);
    
    sendResponse(true, 'Attributes retrieved successfully', [
        'attributes' => $attributes_array
    ]);
    
} catch (Exception $e) {
    sendResponse(false, 'Error retrieving attributes: ' . $e->getMessage(), null, 500);
}

$conn->close();
?> 