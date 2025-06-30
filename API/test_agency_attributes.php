<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Access-Control-Allow-Headers,Content-Type,Access-Control-Allow-Methods,Authorization,X-Requested-With');

include_once 'config/db_connect.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
    exit();
}

try {
    // Test 1: Check all attributes and their creators
    echo "<h2>Test 1: All Attributes and Their Creators</h2>";
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
    echo "<table border='1'>";
    echo "<tr><th>Attribute</th><th>Created By</th><th>Value</th><th>Value Created By</th></tr>";
    while ($row = $result->fetch_assoc()) {
        echo "<tr>";
        echo "<td>{$row['attribute_name']}</td>";
        echo "<td>{$row['created_by_name']} ({$row['created_by_role']})</td>";
        echo "<td>{$row['attribute_value']}</td>";
        echo "<td>{$row['value_created_by_name']} ({$row['value_created_by_role']})</td>";
        echo "</tr>";
    }
    echo "</table>";
    
    // Test 2: Check products and their attributes
    echo "<h2>Test 2: Products and Their Attributes</h2>";
    $query = "
        SELECT 
            p.id as product_id,
            p.name as product_name,
            p.is_agency_product,
            u.username as product_creator,
            u.role as product_creator_role,
            a.name as attribute_name,
            av.value as attribute_value,
            a.created_by as attr_created_by,
            av.created_by as value_created_by
        FROM products p
        JOIN users u ON p.created_by = u.id
        JOIN product_variant pv ON p.id = pv.product_id
        JOIN variants v ON pv.variant_id = v.id
        JOIN variant_attribute_values vav ON v.id = vav.variant_id
        JOIN attribute_values av ON vav.attribute_value_id = av.id
        JOIN attributes a ON av.attribute_id = a.id
        WHERE p.status = 'active'
        ORDER BY p.id, a.name
    ";
    
    $result = $conn->query($query);
    echo "<table border='1'>";
    echo "<tr><th>Product</th><th>Creator</th><th>Is Agency</th><th>Attribute</th><th>Value</th><th>Attr Creator</th><th>Value Creator</th></tr>";
    while ($row = $result->fetch_assoc()) {
        echo "<tr>";
        echo "<td>{$row['product_name']}</td>";
        echo "<td>{$row['product_creator']} ({$row['product_creator_role']})</td>";
        echo "<td>" . ($row['is_agency_product'] ? 'Yes' : 'No') . "</td>";
        echo "<td>{$row['attribute_name']}</td>";
        echo "<td>{$row['attribute_value']}</td>";
        echo "<td>{$row['attr_created_by']}</td>";
        echo "<td>{$row['value_created_by']}</td>";
        echo "</tr>";
    }
    echo "</table>";
    
    // Test 3: Check agency-specific attributes
    echo "<h2>Test 3: Agency-Specific Attributes (What each agency can see)</h2>";
    
    // Get all agencies
    $agency_query = "SELECT id, username FROM users WHERE role = 'agency'";
    $agency_result = $conn->query($agency_query);
    
    while ($agency = $agency_result->fetch_assoc()) {
        echo "<h3>Agency: {$agency['username']} (ID: {$agency['id']})</h3>";
        
        $attr_query = "
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
            WHERE a.created_by IS NULL OR a.created_by = ? OR u.role = 'admin'
            ORDER BY a.name, av.value
        ";
        
        $stmt = $conn->prepare($attr_query);
        $stmt->bind_param("i", $agency['id']);
        $stmt->execute();
        $attr_result = $stmt->get_result();
        
        echo "<table border='1'>";
        echo "<tr><th>Attribute</th><th>Created By</th><th>Value</th><th>Value Created By</th></tr>";
        while ($row = $attr_result->fetch_assoc()) {
            echo "<tr>";
            echo "<td>{$row['attribute_name']}</td>";
            echo "<td>{$row['created_by_name']} ({$row['created_by_role']})</td>";
            echo "<td>{$row['attribute_value']}</td>";
            echo "<td>{$row['value_created_by_name']} ({$row['value_created_by_role']})</td>";
            echo "</tr>";
        }
        echo "</table>";
    }
    
} catch (Exception $e) {
    echo json_encode(['error' => $e->getMessage()]);
}

$conn->close();
?> 