<?php
require_once '../config/db_connect.php';

// Bỏ header để tránh lỗi
// header('Content-Type: application/json');

try {
    // Tạm thời hardcode user ID để test
    $userId = 9; // Agency user ID
    
    echo "=== DEBUG INFO ===\n";
    echo "Using hardcoded User ID: $userId\n";
    
    // Kiểm tra xem có sản phẩm nào thuộc về agency này không
    $stmt = $conn->prepare("
        SELECT p.* 
        FROM products p 
        WHERE p.created_by = ?
    ");
    $stmt->bind_param("i", $userId);
    $stmt->execute();
    $productsResult = $stmt->get_result();
    
    echo "Products found for user $userId: " . $productsResult->num_rows . "\n";
    
    if ($productsResult->num_rows === 0) {
        echo "No products found for this user\n";
        echo "=== END DEBUG ===\n";
        exit;
    }
    
    // Lấy sản phẩm đầu tiên
    $product = $productsResult->fetch_assoc();
    $productId = $product['id'];
    
    echo "Using Product ID: $productId\n";
    
    // Lấy variants của sản phẩm - Sửa query để sử dụng đúng cấu trúc bảng
    $stmt = $conn->prepare("
        SELECT 
            v.id,
            v.sku,
            pv.price,
            pv.stock,
            pv.image_url,
            pv.status,
            pv.product_id,
            GROUP_CONCAT(
                JSON_OBJECT(
                    'id', av.id,
                    'value', av.value,
                    'attribute_id', a.id,
                    'attribute_name', a.name,
                    'created_by', av.created_by
                )
            ) as attributes_json
        FROM variants v
        JOIN product_variant pv ON v.id = pv.variant_id
        LEFT JOIN variant_attribute_values vav ON v.id = vav.variant_id
        LEFT JOIN attribute_values av ON vav.attribute_value_id = av.id
        LEFT JOIN attributes a ON av.attribute_id = a.id
        WHERE pv.product_id = ?
        GROUP BY v.id
    ");
    $stmt->bind_param("i", $productId);
    $stmt->execute();
    $variantsResult = $stmt->get_result();
    
    $variants = [];
    while ($variant = $variantsResult->fetch_assoc()) {
        // Parse attributes JSON
        $attributes = [];
        if ($variant['attributes_json']) {
            $attributesArray = explode(',', $variant['attributes_json']);
            foreach ($attributesArray as $attrJson) {
                $attr = json_decode($attrJson, true);
                if ($attr) {
                    $attributes[] = $attr;
                }
            }
        }
        
        $variants[] = [
            'id' => $variant['id'],
            'sku' => $variant['sku'],
            'price' => $variant['price'],
            'stock' => $variant['stock'],
            'image_url' => $variant['image_url'],
            'status' => $variant['status'],
            'product_id' => $variant['product_id'],
            'attributes' => $attributes
        ];
    }
    
    // Debug: In ra cấu trúc dữ liệu
    echo "Variants count: " . count($variants) . "\n";
    echo "First variant structure:\n";
    if (!empty($variants)) {
        print_r($variants[0]);
    }
    
    // Kiểm tra xem có attribute values nào được gán cho variant này không
    if (!empty($variants)) {
        $variantId = $variants[0]['id'];
        echo "\n=== CHECKING ATTRIBUTE VALUES FOR VARIANT $variantId ===\n";
        
        $stmt = $conn->prepare("
            SELECT vav.variant_id, av.id as value_id, av.value, a.id as attribute_id, a.name as attribute_name
            FROM variant_attribute_values vav
            JOIN attribute_values av ON vav.attribute_value_id = av.id
            JOIN attributes a ON av.attribute_id = a.id
            WHERE vav.variant_id = ?
        ");
        $stmt->bind_param("i", $variantId);
        $stmt->execute();
        $attrResult = $stmt->get_result();
        
        echo "Attribute values found: " . $attrResult->num_rows . "\n";
        while ($attr = $attrResult->fetch_assoc()) {
            echo "- Attribute: {$attr['attribute_name']} = {$attr['value']}\n";
        }
    }
    
    // Test the actual API response format
    echo "\n=== TESTING ACTUAL API RESPONSE FORMAT ===\n";
    
    // Simulate the API response format
    $apiResponse = [
        "success" => true,
        "variants" => []
    ];
    
    foreach ($variants as $variant) {
        // Convert to the format expected by Flutter
        $apiResponse["variants"][] = [
            "variant_id" => $variant['id'],
            "sku" => $variant['sku'],
            "price" => $variant['price'],
            "stock" => $variant['stock'],
            "image_url" => $variant['image_url'],
            "status" => $variant['status'],
            "attribute_values" => $variant['attributes']
        ];
    }
    
    echo "API Response structure:\n";
    print_r($apiResponse);
    
    echo "=== END DEBUG ===\n";
    
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
?> 