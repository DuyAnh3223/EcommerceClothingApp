<?php
header('Content-Type: application/json');

require_once '../config/db_connect.php';

echo "=== Kiểm tra vấn đề Platform Fee ===\n\n";

try {
    // 1. Kiểm tra tất cả sản phẩm agency
    echo "1. Tất cả sản phẩm agency:\n";
    $query = "
        SELECT 
            p.id, p.name, p.is_agency_product, p.status, p.platform_fee_rate,
            u.username as created_by
        FROM products p
        LEFT JOIN users u ON p.created_by = u.id
        WHERE p.is_agency_product = 1
        ORDER BY p.id
    ";
    
    $result = $conn->query($query);
    echo "Tổng số sản phẩm agency: " . $result->num_rows . "\n";
    
    while ($row = $result->fetch_assoc()) {
        echo "- ID: {$row['id']}, Tên: {$row['name']}, Status: {$row['status']}, Fee Rate: {$row['platform_fee_rate']}%, Created by: {$row['created_by']}\n";
    }
    
    // 2. Kiểm tra sản phẩm agency đang active
    echo "\n2. Sản phẩm agency đang active:\n";
    $active_query = "
        SELECT 
            p.id, p.name, p.is_agency_product, p.status, p.platform_fee_rate,
            pv.variant_id, pv.price, pv.status as variant_status
        FROM products p
        JOIN product_variant pv ON p.id = pv.product_id
        WHERE p.is_agency_product = 1 AND p.status = 'active' AND pv.status = 'active'
        ORDER BY p.id
    ";
    
    $active_result = $conn->query($active_query);
    echo "Tổng số sản phẩm agency active: " . $active_result->num_rows . "\n";
    
    while ($row = $active_result->fetch_assoc()) {
        $platform_fee = $row['price'] * ($row['platform_fee_rate'] / 100);
        $final_price = $row['price'] + $platform_fee;
        echo "- Product ID: {$row['id']}, Variant ID: {$row['variant_id']}, Base Price: {$row['price']}, Platform Fee: {$platform_fee}, Final Price: {$final_price}\n";
    }
    
    // 3. Kiểm tra tất cả sản phẩm đang active
    echo "\n3. Tất cả sản phẩm đang active:\n";
    $all_active_query = "
        SELECT 
            p.id, p.name, p.is_agency_product, p.status, p.platform_fee_rate,
            pv.variant_id, pv.price, pv.status as variant_status
        FROM products p
        JOIN product_variant pv ON p.id = pv.product_id
        WHERE p.status = 'active' AND pv.status = 'active'
        ORDER BY p.is_agency_product DESC, p.id
    ";
    
    $all_active_result = $conn->query($all_active_query);
    echo "Tổng số sản phẩm active: " . $all_active_result->num_rows . "\n";
    
    while ($row = $all_active_result->fetch_assoc()) {
        $platform_fee = $row['is_agency_product'] ? ($row['price'] * ($row['platform_fee_rate'] / 100)) : 0;
        $final_price = $row['price'] + $platform_fee;
        $type = $row['is_agency_product'] ? 'AGENCY' : 'ADMIN';
        echo "- [{$type}] Product ID: {$row['id']}, Variant ID: {$row['variant_id']}, Base Price: {$row['price']}, Platform Fee: {$platform_fee}, Final Price: {$final_price}\n";
    }
    
    // 4. Kiểm tra orders gần đây
    echo "\n4. Orders gần đây:\n";
    $orders_query = "
        SELECT 
            o.id, o.total_amount, o.platform_fee, o.status, o.created_at,
            COUNT(oi.id) as item_count
        FROM orders o
        LEFT JOIN order_items oi ON o.id = oi.order_id
        GROUP BY o.id
        ORDER BY o.created_at DESC
        LIMIT 10
    ";
    
    $orders_result = $conn->query($orders_query);
    while ($row = $orders_result->fetch_assoc()) {
        echo "- Order ID: {$row['id']}, Total: {$row['total_amount']}, Platform Fee: {$row['platform_fee']}, Items: {$row['item_count']}, Status: {$row['status']}\n";
    }
    
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}

$conn->close();
?>