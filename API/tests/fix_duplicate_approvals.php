<?php
header('Content-Type: application/json');

require_once '../config/db_connect.php';

echo "=== Fixing Duplicate Product Approvals ===\n\n";

try {
    // Check current duplicates
    echo "=== Current Duplicate Records ===\n";
    $duplicate_query = "
        SELECT product_id, COUNT(*) as count
        FROM product_approvals 
        GROUP BY product_id 
        HAVING COUNT(*) > 1
    ";
    
    $duplicate_result = $conn->query($duplicate_query);
    
    if ($duplicate_result->num_rows > 0) {
        while ($row = $duplicate_result->fetch_assoc()) {
            echo "Product ID: " . $row['product_id'] . " - " . $row['count'] . " records\n";
        }
    } else {
        echo "No duplicates found\n";
    }
    
    // Fix duplicates by keeping only the latest record for each product
    echo "\n=== Fixing Duplicates ===\n";
    
    // Get all product IDs with duplicates
    $product_ids = [];
    $duplicate_result = $conn->query($duplicate_query);
    
    while ($row = $duplicate_result->fetch_assoc()) {
        $product_ids[] = $row['product_id'];
    }
    
    foreach ($product_ids as $product_id) {
        echo "Processing product ID: $product_id\n";
        
        // Get all approval records for this product, ordered by created_at desc
        $records_query = "
            SELECT id, created_at 
            FROM product_approvals 
            WHERE product_id = ? 
            ORDER BY created_at DESC
        ";
        
        $stmt = $conn->prepare($records_query);
        $stmt->bind_param("i", $product_id);
        $stmt->execute();
        $result = $stmt->get_result();
        
        $records = [];
        while ($row = $result->fetch_assoc()) {
            $records[] = $row;
        }
        
        if (count($records) > 1) {
            // Keep the first (latest) record, delete the rest
            $latest_id = $records[0]['id'];
            $delete_ids = [];
            
            for ($i = 1; $i < count($records); $i++) {
                $delete_ids[] = $records[$i]['id'];
            }
            
            if (!empty($delete_ids)) {
                $delete_query = "DELETE FROM product_approvals WHERE id IN (" . implode(',', $delete_ids) . ")";
                if ($conn->query($delete_query)) {
                    echo "  ✓ Deleted " . count($delete_ids) . " duplicate records\n";
                } else {
                    echo "  ✗ Failed to delete duplicates: " . $conn->error . "\n";
                }
            }
        }
    }
    
    // Verify fix
    echo "\n=== Verification ===\n";
    $final_check = $conn->query($duplicate_query);
    
    if ($final_check->num_rows > 0) {
        echo "✗ Still have duplicates:\n";
        while ($row = $final_check->fetch_assoc()) {
            echo "  Product ID: " . $row['product_id'] . " - " . $row['count'] . " records\n";
        }
    } else {
        echo "✓ All duplicates fixed successfully!\n";
    }
    
    // Show final state
    echo "\n=== Final Product Approvals State ===\n";
    $final_query = "
        SELECT 
            pa.id,
            pa.product_id,
            p.name as product_name,
            pa.status,
            pa.review_notes,
            pa.reviewed_at,
            pa.created_at
        FROM product_approvals pa
        JOIN products p ON pa.product_id = p.id
        ORDER BY pa.product_id, pa.created_at DESC
    ";
    
    $final_result = $conn->query($final_query);
    
    while ($row = $final_result->fetch_assoc()) {
        echo "ID: " . $row['id'] . " | Product: " . $row['product_name'] . " | Status: " . $row['status'] . " | Created: " . $row['created_at'] . "\n";
    }
    
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}

$conn->close();
?> 