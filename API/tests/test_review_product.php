<?php
header('Content-Type: application/json');

require_once '../config/db_connect.php';

echo "=== Testing Product Review API ===\n\n";

try {
    // First, let's check current pending products
    echo "=== Current Pending Products ===\n";
    $pending_query = "
        SELECT p.*, pa.status as approval_status
        FROM products p
        LEFT JOIN product_approvals pa ON p.id = pa.product_id
        WHERE p.is_agency_product = 1 AND p.status = 'pending'
    ";
    
    $pending_result = $conn->query($pending_query);
    echo "Pending products found: " . $pending_result->num_rows . "\n";
    
    if ($pending_result->num_rows > 0) {
        while ($row = $pending_result->fetch_assoc()) {
            echo "Product ID: " . $row['id'] . " - " . $row['name'] . "\n";
        }
    }
    
    // If no pending products, let's create one for testing
    if ($pending_result->num_rows === 0) {
        echo "\nNo pending products found. Creating a test product...\n";
        
        // Update an existing product to pending status
        $update_query = "
            UPDATE products 
            SET status = 'pending', updated_at = NOW() 
            WHERE id = 16 AND is_agency_product = 1
        ";
        
        if ($conn->query($update_query)) {
            echo "Updated product ID 16 to pending status\n";
            
            // Create approval record
            $approval_query = "
                INSERT INTO product_approvals (product_id, status, created_at) 
                VALUES (16, 'pending', NOW())
            ";
            
            if ($conn->query($approval_query)) {
                echo "Created approval record for product ID 16\n";
            }
        }
    }
    
    // Now test the review API
    echo "\n=== Testing Review API ===\n";
    
    // Simulate approve action
    $approve_data = [
        'product_id' => 16,
        'action' => 'approve',
        'review_notes' => 'Test approval'
    ];
    
    echo "Testing approve action for product ID 16...\n";
    
    // Simulate the API call
    $stmt = $conn->prepare("
        SELECT p.*, u.id as creator_id, u.username as creator_name
        FROM products p 
        JOIN users u ON p.created_by = u.id 
        WHERE p.id = ? AND p.is_agency_product = 1 AND p.status = 'pending'
    ");
    $productId = 16;
    $stmt->bind_param("i", $productId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        $product = $result->fetch_assoc();
        
        // Update product status
        $update_stmt = $conn->prepare("
            UPDATE products 
            SET status = 'active', updated_at = NOW() 
            WHERE id = ?
        ");
        $updateProductId = 16;
        $update_stmt->bind_param("i", $updateProductId);
        
        if ($update_stmt->execute()) {
            echo "✓ Product status updated to active\n";
            
            // Create approval record
            $approval_stmt = $conn->prepare("
                INSERT INTO product_approvals (product_id, status, reviewed_by, review_notes, reviewed_at, created_at) 
                VALUES (?, 'approved', ?, ?, NOW(), NOW())
            ");
            $productId = 16;
            $adminId = 6; // Use actual admin user ID
            $reviewNotes = 'Test approval';
            $approval_stmt->bind_param("iis", $productId, $adminId, $reviewNotes);
            
            if ($approval_stmt->execute()) {
                echo "✓ Approval record created\n";
            } else {
                echo "✗ Failed to create approval record: " . $approval_stmt->error . "\n";
            }
        } else {
            echo "✗ Failed to update product status: " . $update_stmt->error . "\n";
        }
    } else {
        echo "✗ Product not found or not pending\n";
    }
    
    // Check final status
    echo "\n=== Final Status Check ===\n";
    $final_query = "
        SELECT 
            p.id,
            p.name,
            p.status,
            pa.status as approval_status,
            pa.review_notes,
            pa.reviewed_at
        FROM products p
        LEFT JOIN product_approvals pa ON p.id = pa.product_id
        WHERE p.id IN (15, 16) AND p.is_agency_product = 1
        ORDER BY p.id
    ";
    
    $final_result = $conn->query($final_query);
    
    while ($row = $final_result->fetch_assoc()) {
        echo "Product ID: " . $row['id'] . "\n";
        echo "Name: " . $row['name'] . "\n";
        echo "Status: " . $row['status'] . "\n";
        echo "Approval Status: " . ($row['approval_status'] ?? 'NULL') . "\n";
        echo "Review Notes: " . ($row['review_notes'] ?? 'NULL') . "\n";
        echo "Reviewed At: " . ($row['reviewed_at'] ?? 'NULL') . "\n";
        echo "---\n";
    }
    
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}

$conn->close();
?> 