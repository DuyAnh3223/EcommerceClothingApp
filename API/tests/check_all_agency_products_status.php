<?php
header('Content-Type: application/json');

require_once '../config/db_connect.php';

echo "=== Checking All Agency Products Status ===\n\n";

try {
    // Get all agency products with their current status
    $query = "
        SELECT 
            p.id,
            p.name,
            p.status,
            p.created_at,
            p.updated_at,
            pa.status as approval_status,
            pa.review_notes,
            pa.reviewed_at,
            u.username as agency_name,
            reviewer.username as reviewer_name
        FROM products p
        LEFT JOIN (
            SELECT pa1.*
            FROM product_approvals pa1
            INNER JOIN (
                SELECT product_id, MAX(created_at) as max_created_at
                FROM product_approvals
                GROUP BY product_id
            ) pa2 ON pa1.product_id = pa2.product_id AND pa1.created_at = pa2.max_created_at
        ) pa ON p.id = pa.product_id
        LEFT JOIN users u ON p.created_by = u.id
        LEFT JOIN users reviewer ON pa.reviewed_by = reviewer.id
        WHERE p.is_agency_product = 1
        ORDER BY p.created_at DESC
    ";
    
    $result = $conn->query($query);
    
    echo "Total agency products: " . $result->num_rows . "\n\n";
    
    if ($result->num_rows > 0) {
        while ($row = $result->fetch_assoc()) {
            echo "Product ID: " . $row['id'] . "\n";
            echo "Product Name: " . $row['name'] . "\n";
            echo "Product Status: " . $row['status'] . "\n";
            echo "Approval Status: " . ($row['approval_status'] ?? 'NULL') . "\n";
            echo "Agency: " . $row['agency_name'] . "\n";
            echo "Reviewer: " . ($row['reviewer_name'] ?? 'NULL') . "\n";
            echo "Review Notes: " . ($row['review_notes'] ?? 'NULL') . "\n";
            echo "Reviewed At: " . ($row['reviewed_at'] ?? 'NULL') . "\n";
            echo "Created At: " . $row['created_at'] . "\n";
            echo "Updated At: " . $row['updated_at'] . "\n";
            echo "---\n";
        }
    }
    
    // Check product_approvals table for all records
    echo "\n=== All Product Approvals Records ===\n";
    $pa_query = "
        SELECT 
            pa.*,
            p.name as product_name,
            u.username as agency_name,
            reviewer.username as reviewer_name
        FROM product_approvals pa
        LEFT JOIN products p ON pa.product_id = p.id
        LEFT JOIN users u ON p.created_by = u.id
        LEFT JOIN users reviewer ON pa.reviewed_by = reviewer.id
        ORDER BY pa.product_id, pa.created_at
    ";
    
    $pa_result = $conn->query($pa_query);
    
    echo "Total approval records: " . $pa_result->num_rows . "\n\n";
    
    if ($pa_result->num_rows > 0) {
        while ($row = $pa_result->fetch_assoc()) {
            echo "Product ID: " . $row['product_id'] . "\n";
            echo "Product Name: " . $row['product_name'] . "\n";
            echo "Approval Status: " . $row['status'] . "\n";
            echo "Review Notes: " . ($row['review_notes'] ?? 'NULL') . "\n";
            echo "Reviewed By: " . ($row['reviewer_name'] ?? 'NULL') . "\n";
            echo "Reviewed At: " . ($row['reviewed_at'] ?? 'NULL') . "\n";
            echo "Created At: " . $row['created_at'] . "\n";
            echo "---\n";
        }
    }
    
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}

$conn->close();
?> 