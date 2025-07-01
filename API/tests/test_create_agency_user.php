<?php
header('Content-Type: application/json');

require_once 'config/db_connect.php';

try {
    $conn->begin_transaction();
    
    // 1. Tạo user agency
    $agency_username = 'agency_test';
    $agency_email = 'agency@gmail.com';
    $agency_phone = '0987654321';
    $agency_password = md5('123456'); // Password: 123456
    
    $stmt = $conn->prepare("
        INSERT INTO users (username, email, phone, password, role) 
        VALUES (?, ?, ?, ?, 'agency')
    ");
    $stmt->bind_param("ssss", $agency_username, $agency_email, $agency_phone, $agency_password);
    $stmt->execute();
    $agency_user_id = $conn->insert_id;
    
    echo "Created agency user with ID: $agency_user_id\n";
    
    // 2. Tạo sản phẩm mẫu cho agency
    $product_name = 'Áo thun Agency Test';
    $product_description = 'Sản phẩm test do agency tạo ra';
    $product_category = 'T-Shirts';
    $product_gender = 'unisex';
    $product_image = 'test_agency_product.jpg';
    
    $stmt = $conn->prepare("
        INSERT INTO products (name, description, category, gender_target, main_image, created_by, is_agency_product, status, platform_fee_rate) 
        VALUES (?, ?, ?, ?, ?, ?, 1, 'pending', 20.00)
    ");
    $stmt->bind_param("sssssi", $product_name, $product_description, $product_category, $product_gender, $product_image, $agency_user_id);
    $stmt->execute();
    $product_id = $conn->insert_id;
    
    echo "Created product with ID: $product_id\n";
    
    // 3. Tạo variant cho sản phẩm
    $variant_sku = 'AGENCY-TEST-001';
    $variant_price = 150000;
    $variant_stock = 50;
    
    // Tạo variant
    $stmt = $conn->prepare("INSERT INTO variants (sku) VALUES (?)");
    $stmt->bind_param("s", $variant_sku);
    $stmt->execute();
    $variant_id = $conn->insert_id;
    
    // Liên kết variant với sản phẩm
    $stmt = $conn->prepare("
        INSERT INTO product_variant (product_id, variant_id, price, stock, status) 
        VALUES (?, ?, ?, ?, 'active')
    ");
    $stmt->bind_param("iidi", $product_id, $variant_id, $variant_price, $variant_stock);
    $stmt->execute();
    
    echo "Created variant with ID: $variant_id\n";
    
    // 4. Liên kết variant với attributes có sẵn
    // Lấy attribute values có sẵn (color: black, size: X)
    $stmt = $conn->prepare("
        SELECT av.id FROM attribute_values av 
        JOIN attributes a ON av.attribute_id = a.id 
        WHERE (a.name = 'color' AND av.value = 'black') 
        OR (a.name = 'size' AND av.value = 'X')
    ");
    $stmt->execute();
    $result = $stmt->get_result();
    
    while ($row = $result->fetch_assoc()) {
        $attr_value_id = $row['id'];
        $stmt2 = $conn->prepare("
            INSERT INTO variant_attribute_values (variant_id, attribute_value_id) 
            VALUES (?, ?)
        ");
        $stmt2->bind_param("ii", $variant_id, $attr_value_id);
        $stmt2->execute();
    }
    
    echo "Linked variant with attributes\n";
    
    // 5. Tạo thêm một sản phẩm nữa
    $product_name2 = 'Quần jean Agency Test';
    $product_description2 = 'Quần jean test do agency tạo ra';
    $product_category2 = 'Jeans';
    
    $stmt = $conn->prepare("
        INSERT INTO products (name, description, category, gender_target, main_image, created_by, is_agency_product, status, platform_fee_rate) 
        VALUES (?, ?, ?, ?, ?, ?, 1, 'draft', 20.00)
    ");
    $stmt->bind_param("sssssi", $product_name2, $product_description2, $product_category2, $product_gender, $product_image, $agency_user_id);
    $stmt->execute();
    $product_id2 = $conn->insert_id;
    
    echo "Created second product with ID: $product_id2\n";
    
    $conn->commit();
    
    echo json_encode([
        'success' => true,
        'message' => 'Test data created successfully',
        'data' => [
            'agency_user_id' => $agency_user_id,
            'agency_username' => $agency_username,
            'agency_password' => '123456',
            'products_created' => [$product_id, $product_id2],
            'variant_created' => $variant_id
        ]
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