<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once __DIR__ . '/../../config/db_connect.php';

// Only get active products (approved and active)
$sql = "SELECT id, name, description, category, gender_target, main_image, created_at, updated_at, is_agency_product, platform_fee_rate, created_by FROM products WHERE status = 'active' ORDER BY id";
$result = $conn->query($sql);
if (!$result) {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Lỗi: " . $conn->error
    ]);
    $conn->close();
    exit();
}

$products = [];
while ($row = $result->fetch_assoc()) {
    $product_id = (int)$row['id'];
    $is_agency_product = (bool)$row['is_agency_product'];
    $platform_fee_rate = (float)$row['platform_fee_rate'];
    
    // Lấy variants động cho sản phẩm này
    $variant_sql = "SELECT v.id as variant_id, v.sku, pv.price, pv.stock, pv.status, pv.image_url
                    FROM product_variant pv
                    JOIN variants v ON pv.variant_id = v.id
                    WHERE pv.product_id = ? AND pv.status = 'active'";
    $variant_stmt = $conn->prepare($variant_sql);
    $variant_stmt->bind_param("i", $product_id);
    $variant_stmt->execute();
    $variant_result = $variant_stmt->get_result();
    $variants = [];
    while ($vrow = $variant_result->fetch_assoc()) {
        $variant_id = (int)$vrow['variant_id'];
        $base_price = (float)$vrow['price'];
        
        // Calculate final price with platform fee for agency products
        $final_price = $base_price;
        $platform_fee = 0;
        if ($is_agency_product) {
            $platform_fee = $base_price * ($platform_fee_rate / 100);
            $final_price = $base_price + $platform_fee;
        }
        
        // Lấy các giá trị thuộc tính của variant này
        $attr_sql = "SELECT av.id as value_id, av.value, a.id as attribute_id, a.name as attribute_name
                     FROM variant_attribute_values vav
                     JOIN attribute_values av ON vav.attribute_value_id = av.id
                     JOIN attributes a ON av.attribute_id = a.id
                     WHERE vav.variant_id = ?";
        $attr_stmt = $conn->prepare($attr_sql);
        $attr_stmt->bind_param("i", $variant_id);
        $attr_stmt->execute();
        $attr_result = $attr_stmt->get_result();
        $attribute_values = [];
        while ($arow = $attr_result->fetch_assoc()) {
            $attribute_values[] = [
                'attribute_id' => (int)$arow['attribute_id'],
                'attribute_name' => $arow['attribute_name'],
                'value_id' => (int)$arow['value_id'],
                'value' => $arow['value']
            ];
        }
        $attr_stmt->close();
        $variants[] = [
            'variant_id' => $variant_id,
            'sku' => $vrow['sku'],
            'price' => $final_price,
            'base_price' => $base_price,
            'platform_fee' => $platform_fee,
            'stock' => (int)$vrow['stock'],
            'status' => $vrow['status'],
            'image_url' => $vrow['image_url'],
            'attribute_values' => $attribute_values
        ];
    }
    $variant_stmt->close();
    $products[] = [
        'id' => $product_id,
        'name' => $row['name'],
        'description' => $row['description'],
        'category' => $row['category'],
        'gender_target' => $row['gender_target'],
        'main_image' => $row['main_image'],
        'is_agency_product' => $is_agency_product,
        'platform_fee_rate' => $platform_fee_rate,
        'created_by' => $row['created_by'],
        'created_at' => $row['created_at'],
        'updated_at' => $row['updated_at'],
        'variants' => $variants
    ];
}

http_response_code(200);
echo json_encode([
    "success" => true,
    "message" => "Lấy danh sách sản phẩm thành công",
    "data" => $products
]);
$conn->close();
?>