<?php
header('Content-Type: application/json');

require_once '../config/db_connect.php';

echo "=== Testing Admin Products API ===\n\n";

try {
    // Test different statuses
    $statuses = ['pending', 'approved', 'rejected'];
    
    foreach ($statuses as $status) {
        echo "=== Testing status: $status ===\n";
        
        // Get products for this status
        $query = "
            SELECT 
                p.*,
                pa.status as approval_status,
                pa.review_notes,
                pa.reviewed_at,
                u.username as agency_name,
                u.email as agency_email,
                u.phone as agency_phone,
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
            WHERE p.is_agency_product = 1 AND p.status = ?
            ORDER BY p.created_at DESC
        ";
        
        $stmt = $conn->prepare($query);
        $stmt->bind_param("s", $status);
        $stmt->execute();
        $result = $stmt->get_result();
        
        echo "Total products found: " . $result->num_rows . "\n\n";
        
        $products = [];
        $seen_products = []; // Track seen product IDs to avoid duplicates
        
        while ($row = $result->fetch_assoc()) {
            // Skip if we've already processed this product
            if (in_array($row['id'], $seen_products)) {
                continue;
            }
            
            $seen_products[] = $row['id'];
            
            echo "Product ID: " . $row['id'] . "\n";
            echo "Product Name: " . $row['name'] . "\n";
            echo "Status: " . $row['status'] . "\n";
            echo "Approval Status: " . ($row['approval_status'] ?? 'NULL') . "\n";
            echo "Agency: " . $row['agency_name'] . "\n";
            echo "Created At: " . $row['created_at'] . "\n";
            echo "---\n";
            
            // Get variants for this product
            $variant_query = "
                SELECT 
                    v.id as variant_id,
                    v.sku,
                    pv.price,
                    pv.stock,
                    pv.image_url,
                    pv.status as variant_status
                FROM product_variant pv
                JOIN variants v ON pv.variant_id = v.id
                WHERE pv.product_id = ?
            ";
            $stmt = $conn->prepare($variant_query);
            $stmt->bind_param("i", $row['id']);
            $stmt->execute();
            $variants_result = $stmt->get_result();
            
            echo "Variants count: " . $variants_result->num_rows . "\n";
            
            $variants = [];
            while ($variant = $variants_result->fetch_assoc()) {
                $variants[] = $variant;
            }
            
            $row['variants'] = $variants;
            $products[] = $row;
        }
        
        echo "\n=== Final JSON Response for $status ===\n";
        echo json_encode([
            'success' => true,
            'message' => 'Products retrieved successfully',
            'data' => [
                'products' => $products,
                'total' => count($products),
                'page' => 1,
                'limit' => 10
            ]
        ], JSON_PRETTY_PRINT);
        
        echo "\n\n";
    }
    
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}

$conn->close();
?> 