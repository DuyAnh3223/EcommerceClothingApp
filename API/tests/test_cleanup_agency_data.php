<?php
header('Content-Type: application/json');

require_once 'config/db_connect.php';

try {
    $conn->begin_transaction();
    
    // 1. Xóa tất cả sản phẩm của agency
    $stmt = $conn->prepare("
        DELETE pv FROM product_variant pv
        JOIN products p ON pv.product_id = p.id
        WHERE p.is_agency_product = 1
    ");
    $stmt->execute();
    echo "Deleted agency product variants\n";
    
    // 2. Xóa variants không còn được sử dụng
    $stmt = $conn->prepare("
        DELETE v FROM variants v
        WHERE v.id NOT IN (SELECT DISTINCT variant_id FROM product_variant)
    ");
    $stmt->execute();
    echo "Deleted unused variants\n";
    
    // 3. Xóa sản phẩm của agency
    $stmt = $conn->prepare("DELETE FROM products WHERE is_agency_product = 1");
    $stmt->execute();
    $deleted_products = $stmt->affected_rows;
    echo "Deleted $deleted_products agency products\n";
    
    // 4. Xóa user agency
    $stmt = $conn->prepare("DELETE FROM users WHERE role = 'agency'");
    $stmt->execute();
    $deleted_users = $stmt->affected_rows;
    echo "Deleted $deleted_users agency users\n";
    
    $conn->commit();
    
    echo json_encode([
        'success' => true,
        'message' => 'Agency test data cleaned up successfully',
        'deleted_products' => $deleted_products,
        'deleted_users' => $deleted_users
    ]);
    
} catch (Exception $e) {
    $conn->rollback();
    echo json_encode([
        'success' => false,
        'message' => 'Error: ' . $e->getMessage()
    ]);
}

$conn->close();
?> 