<?php
header('Content-Type: application/json');

require_once '../config/db_connect.php';

// Test get products API
echo "=== Testing Agency Products API ===\n";

try {
    // Simulate agency user (replace with actual agency user ID)
    $agencyUserId = 9; // Agency user ID
    
    // Get products for this agency (with duplicate prevention)
    $query = "
        SELECT 
            p.*,
            pa.status as approval_status,
            pa.review_notes,
            pa.reviewed_at,
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
        LEFT JOIN users reviewer ON pa.reviewed_by = reviewer.id
        WHERE p.created_by = ? AND p.is_agency_product = 1
        ORDER BY p.created_at DESC
    ";
    
    $stmt = $conn->prepare($query);
    $stmt->bind_param("i", $agencyUserId);
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
        echo "Created At: " . $row['created_at'] . "\n";
        echo "---\n";
        
        // Get variants for this product
        $variant_query = "
            SELECT 
                v.id,
                v.sku,
                pv.price,
                pv.stock,
                pv.image_url,
                pv.status,
                pv.product_id
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
            // Get attributes for this variant
            $attr_query = "
                SELECT 
                    av.id,
                    av.value,
                    av.attribute_id,
                    a.name as attribute_name
                FROM variant_attribute_values vav
                JOIN attribute_values av ON vav.attribute_value_id = av.id
                JOIN attributes a ON av.attribute_id = a.id
                WHERE vav.variant_id = ?
                ORDER BY a.name, av.value
            ";
            $stmt = $conn->prepare($attr_query);
            $stmt->bind_param("i", $variant['id']);
            $stmt->execute();
            $attrs_result = $stmt->get_result();
            
            $attributes = [];
            while ($attr = $attrs_result->fetch_assoc()) {
                $attributes[] = [
                    'id' => $attr['id'],
                    'value' => $attr['value'],
                    'attribute_id' => $attr['attribute_id'],
                    'attribute_name' => $attr['attribute_name']
                ];
            }
            
            $variant['attributes'] = $attributes;
            $variants[] = $variant;
        }
        
        $row['variants'] = $variants;
        $products[] = $row;
    }
    
    echo "\n=== Final JSON Response ===\n";
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
    
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}

$conn->close();
?> 