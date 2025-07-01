<?php
header('Content-Type: application/json');

require_once '../config/db_connect.php';

echo "=== Checking for Duplicate Products ===\n\n";

try {
    // Check for duplicate products by name and created_by
    $query = "
        SELECT 
            name,
            created_by,
            COUNT(*) as count,
            GROUP_CONCAT(id ORDER BY id) as product_ids,
            GROUP_CONCAT(status ORDER BY id) as statuses,
            GROUP_CONCAT(created_at ORDER BY id) as created_ats
        FROM products 
        WHERE is_agency_product = 1
        GROUP BY name, created_by
        HAVING COUNT(*) > 1
        ORDER BY name
    ";
    
    $result = $conn->query($query);
    
    echo "Duplicate products found: " . $result->num_rows . "\n\n";
    
    if ($result->num_rows > 0) {
        while ($row = $result->fetch_assoc()) {
            echo "Product Name: " . $row['name'] . "\n";
            echo "Created By: " . $row['created_by'] . "\n";
            echo "Count: " . $row['count'] . "\n";
            echo "Product IDs: " . $row['product_ids'] . "\n";
            echo "Statuses: " . $row['statuses'] . "\n";
            echo "Created Ats: " . $row['created_ats'] . "\n";
            echo "---\n";
        }
    } else {
        echo "No duplicate products found in database.\n";
    }
    
    // Check all products for agency user 9
    echo "\n=== All Products for Agency User 9 ===\n";
    $query2 = "
        SELECT 
            id,
            name,
            status,
            created_at,
            updated_at
        FROM products 
        WHERE created_by = 9 AND is_agency_product = 1
        ORDER BY created_at DESC
    ";
    
    $result2 = $conn->query($query2);
    
    echo "Total products for agency user 9: " . $result2->num_rows . "\n\n";
    
    while ($row = $result2->fetch_assoc()) {
        echo "ID: " . $row['id'] . "\n";
        echo "Name: " . $row['name'] . "\n";
        echo "Status: " . $row['status'] . "\n";
        echo "Created: " . $row['created_at'] . "\n";
        echo "Updated: " . $row['updated_at'] . "\n";
        echo "---\n";
    }
    
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}

$conn->close();
?> 