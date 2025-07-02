<?php
header('Content-Type: application/json');

require_once '../config/db_connect.php';

echo "=== Tạo sản phẩm Agency Test ===\n\n";

try {
    $conn->begin_transaction();
    
    // 1. Tìm user agency
    $agency_query = "SELECT id, username FROM users WHERE role = 'agency' LIMIT 1";
    $agency_result = $conn->query($agency_query);
    
    if ($agency_result->num_rows === 0) {
        echo "Không tìm thấy user agency nào. Tạo user agency mới...\n";
        
        $stmt = $conn->prepare("
            INSERT INTO users (username, email, phone, password, role) 
            VALUES ('test_agency', 'test_agency@gmail.com', '0123456789', ?, 'agency')
        ");
        $password = md5('123456');
        $stmt->bind_param("s", $password);
        $stmt->execute();
        $agency_user_id = $conn->insert_id;
        echo "Đã tạo user agency với ID: $agency_user_id\n";
    } else {
        $agency_user = $agency_result->fetch_assoc();
        $agency_user_id = $agency_user['id'];
        echo "Sử dụng user agency hiện có: {$agency_user['username']} (ID: $agency_user_id)\n";
    }
    
    // 2. Tạo sản phẩm agency
    $product_name = 'Áo thun Agency Test Platform Fee';
    $product_description = 'Sản phẩm test để kiểm tra platform fee';
    $product_category = 'T-Shirts';
    $product_gender = 'unisex';
    $product_image = 'test_agency_platform_fee.jpg';
    
    $stmt = $conn->prepare("
        INSERT INTO products (name, description, category, gender_target, main_image, created_by, is_agency_product, status, platform_fee_rate) 
        VALUES (?, ?, ?, ?, ?, ?, 1, 'active', 20.00)
    ");
    $stmt->bind_param("sssssi", $product_name, $product_description, $product_category, $product_gender, $product_image, $agency_user_id);
    $stmt->execute();
    $product_id = $conn->insert_id;
    
    echo "Đã tạo sản phẩm agency với ID: $product_id\n";
    
    // 3. Tạo variant cho sản phẩm
    $variant_sku = 'AGENCY-PLATFORM-FEE-001';
    $variant_price = 200000; // 200,000 VND
    $variant_stock = 100;
    
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
    
    echo "Đã tạo variant với ID: $variant_id, Price: $variant_price VND\n";
    
    // 4. Liên kết variant với attributes có sẵn (color: black, size: L)
    $stmt = $conn->prepare("
        SELECT av.id FROM attribute_values av 
        JOIN attributes a ON av.attribute_id = a.id 
        WHERE (a.name = 'color' AND av.value = 'black') 
        OR (a.name = 'size' AND av.value = 'L')
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
    
    echo "Đã liên kết variant với attributes\n";
    
    // 5. Tính toán platform fee
    $platform_fee_rate = 20.00; // 20%
    $platform_fee = $variant_price * ($platform_fee_rate / 100);
    $final_price = $variant_price + $platform_fee;
    
    echo "\n=== Thông tin sản phẩm ===\n";
    echo "Product ID: $product_id\n";
    echo "Variant ID: $variant_id\n";
    echo "Base Price: $variant_price VND\n";
    echo "Platform Fee Rate: $platform_fee_rate%\n";
    echo "Platform Fee: $platform_fee VND\n";
    echo "Final Price: $final_price VND\n";
    
    $conn->commit();
    
    echo "\n✅ Đã tạo thành công sản phẩm agency test với platform fee!\n";
    echo "Bây giờ bạn có thể test tạo order với sản phẩm này để xem platform fee có được tính đúng không.\n";
    
} catch (Exception $e) {
    $conn->rollback();
    echo "❌ Lỗi: " . $e->getMessage() . "\n";
}

$conn->close();
?>