<?php
require_once 'config/config.php';
require_once 'utils/response.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    $conn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);
    
    if ($conn->connect_error) {
        sendResponse(false, 'Connection failed: ' . $conn->connect_error, null, 500);
        exit();
    }
    
    // Test 1: Kiểm tra kết nối database
    $test_sql = "SELECT COUNT(*) as total FROM products";
    $result = $conn->query($test_sql);
    $total_products = $result->fetch_assoc()['total'];
    
    // Test 2: Kiểm tra bảng product_variant
    $test_sql2 = "SELECT COUNT(*) as total FROM product_variant";
    $result2 = $conn->query($test_sql2);
    $total_variants = $result2->fetch_assoc()['total'];
    
    // Test 3: Kiểm tra bảng users
    $test_sql3 = "SELECT COUNT(*) as total FROM users";
    $result3 = $conn->query($test_sql3);
    $total_users = $result3->fetch_assoc()['total'];
    
    // Test 4: Kiểm tra bảng user_addresses
    $test_sql4 = "SELECT COUNT(*) as total FROM user_addresses";
    $result4 = $conn->query($test_sql4);
    $total_addresses = $result4->fetch_assoc()['total'];
    
    // Test 5: Lấy một số sản phẩm mẫu để test
    $sample_sql = "SELECT p.id as product_id, p.name, pv.variant_id, pv.price, pv.stock 
                   FROM products p 
                   JOIN product_variant pv ON p.id = pv.product_id 
                   LIMIT 3";
    $sample_result = $conn->query($sample_sql);
    $sample_products = [];
    while ($row = $sample_result->fetch_assoc()) {
        $sample_products[] = [
            'product_id' => (int)$row['product_id'],
            'name' => $row['name'],
            'variant_id' => (int)$row['variant_id'],
            'price' => (float)$row['price'],
            'stock' => (int)$row['stock']
        ];
    }
    
    $conn->close();
    
    sendResponse(true, 'Place order API test completed successfully', [
        'database_connection' => 'OK',
        'total_products' => (int)$total_products,
        'total_variants' => (int)$total_variants,
        'total_users' => (int)$total_users,
        'total_addresses' => (int)$total_addresses,
        'sample_products' => $sample_products,
        'test_data' => [
            'single_order' => [
                'user_id' => 4,
                'product_id' => $sample_products[0]['product_id'] ?? 1,
                'variant_id' => $sample_products[0]['variant_id'] ?? 1,
                'quantity' => 1,
                'address_id' => 3,
                'payment_method' => 'COD'
            ],
            'multi_order' => [
                'user_id' => 4,
                'address_id' => 3,
                'payment_method' => 'COD',
                'items' => [
                    [
                        'product_id' => $sample_products[0]['product_id'] ?? 1,
                        'variant_id' => $sample_products[0]['variant_id'] ?? 1,
                        'quantity' => 1
                    ]
                ]
            ]
        ]
    ]);
    
} catch (Exception $e) {
    sendResponse(false, 'Server error: ' . $e->getMessage(), null, 500);
}
?> 