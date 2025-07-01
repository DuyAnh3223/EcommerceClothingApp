<?php
header('Content-Type: application/json');

require_once '../config/db_connect.php';

echo "=== Checking Product Approvals Table ===\n\n";

try {
    // Check all records in product_approvals table
    $query = "
        SELECT 
            pa.*,
            p.name as product_name,
            u.username as reviewer_username
        FROM product_approvals pa
        LEFT JOIN products p ON pa.product_id = p.id
        LEFT JOIN users u ON pa.reviewed_by = u.id
        ORDER BY pa.product_id, pa.created_at
    ";
    
    $result = $conn->query($query);
    
    echo "Total product_approvals records: " . $result->num_rows . "\n\n";
    
    if ($result->num_rows > 0) {
        while ($row = $result->fetch_assoc()) {
            echo "Product ID: " . $row['product_id'] . "\n";
            echo "Product Name: " . $row['product_name'] . "\n";
            echo "Status: " . $row['status'] . "\n";
            echo "Created At: " . $row['created_at'] . "\n";
            echo "Reviewed By: " . ($row['reviewer_username'] ?? 'NULL') . "\n";
            echo "Reviewed At: " . ($row['reviewed_at'] ?? 'NULL') . "\n";
            echo "---\n";
        }
    }
    
    // Check for duplicate approvals for same product
    echo "\n=== Checking for Duplicate Approvals ===\n";
    $dup_query = "
        SELECT 
            product_id,
            COUNT(*) as count,
            GROUP_CONCAT(status ORDER BY created_at) as statuses,
            GROUP_CONCAT(created_at ORDER BY created_at) as created_ats
        FROM product_approvals
        GROUP BY product_id
        HAVING COUNT(*) > 1
        ORDER BY product_id
    ";
    
    $dup_result = $conn->query($dup_query);
    
    echo "Products with duplicate approvals: " . $dup_result->num_rows . "\n\n";
    
    if ($dup_result->num_rows > 0) {
        while ($row = $dup_result->fetch_assoc()) {
            echo "Product ID: " . $row['product_id'] . "\n";
            echo "Count: " . $row['count'] . "\n";
            echo "Statuses: " . $row['statuses'] . "\n";
            echo "Created Ats: " . $row['created_ats'] . "\n";
            echo "---\n";
        }
    }
    
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}

$conn->close();
?> 