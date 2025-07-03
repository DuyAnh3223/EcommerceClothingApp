<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../config/db_connect.php';

$user_id = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
if (!$user_id) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Thiếu user_id."
    ]);
    exit();
}

// Lấy cả sản phẩm đơn lẻ và combo
$sql = "SELECT ci.id AS cart_item_id, 
               ci.product_id, ci.variant_id, ci.quantity,
               ci.combination_id, ci.combination_name, ci.combination_image, ci.combination_price, ci.combination_items,
               p.name as product_name, p.main_image as product_image, p.is_agency_product, p.platform_fee_rate,
               pv.price, pv.stock, pv.image_url as variant_image
        FROM cart_items ci
        LEFT JOIN products p ON ci.product_id = p.id
        LEFT JOIN product_variant pv ON ci.product_id = pv.product_id AND ci.variant_id = pv.variant_id
        WHERE ci.user_id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $user_id);
$stmt->execute();
$result = $stmt->get_result();
$cart = [];

while ($row = $result->fetch_assoc()) {
    if ($row['combination_id'] !== null) {
        // Đây là combo
        $combination_price = (float)$row['combination_price'];
        $total_price = $combination_price * (int)$row['quantity'];
        
        // Parse combination_items JSON và lấy thông tin chi tiết
        $combination_items = [];
        if (!empty($row['combination_items'])) {
            $basic_items = json_decode($row['combination_items'], true);
            
            // Lấy thông tin chi tiết cho từng item
            foreach ($basic_items as $basic_item) {
                $product_id = (int)$basic_item['product_id'];
                $variant_id = (int)$basic_item['variant_id'];
                
                // Lấy thông tin sản phẩm
                $product_sql = "SELECT p.name as product_name, p.main_image as product_image, p.category as product_category,
                                      pv.price, pv.stock, pv.image_url as variant_image
                               FROM products p
                               LEFT JOIN product_variant pv ON p.id = pv.product_id AND pv.variant_id = ?
                               WHERE p.id = ?";
                $product_stmt = $conn->prepare($product_sql);
                $product_stmt->bind_param("ii", $variant_id, $product_id);
                $product_stmt->execute();
                $product_result = $product_stmt->get_result();
                
                if ($product_result->num_rows > 0) {
                    $product_row = $product_result->fetch_assoc();
                    
                    // Lấy thuộc tính của variant
                    $attr_sql = "SELECT a.name as attribute_name, av.value
                                 FROM variant_attribute_values vav
                                 JOIN attribute_values av ON vav.attribute_value_id = av.id
                                 JOIN attributes a ON av.attribute_id = a.id
                                 WHERE vav.variant_id = ?";
                    $attr_stmt = $conn->prepare($attr_sql);
                    $attr_stmt->bind_param("i", $variant_id);
                    $attr_stmt->execute();
                    $attr_result = $attr_stmt->get_result();
                    $attributes = [];
                    while ($arow = $attr_result->fetch_assoc()) {
                        $attributes[$arow['attribute_name']] = $arow['value'];
                    }
                    $attr_stmt->close();
                    
                    $combination_items[] = array_merge($basic_item, [
                        'product_name' => $product_row['product_name'],
                        'product_image' => $product_row['product_image'],
                        'product_category' => $product_row['product_category'],
                        'price' => (float)$product_row['price'],
                        'stock' => (int)$product_row['stock'],
                        'variant_image' => $product_row['variant_image'],
                        'attributes' => $attributes,
                        'image_url' => !empty($product_row['variant_image']) ? $product_row['variant_image'] : $product_row['product_image']
                    ]);
                }
                
                $product_stmt->close();
            }
        }
        
        // Xác định hình ảnh cho combo: ưu tiên combination_image, nếu không có thì dùng hình ảnh sản phẩm đầu tiên
        $combo_image = $row['combination_image'];
        if (empty($combo_image) && !empty($combination_items)) {
            $first_item = $combination_items[0];
            $combo_image = $first_item['image_url'] ?? $first_item['product_image'] ?? $first_item['variant_image'] ?? '';
        }
        
        $cart[] = [
            'cart_item_id' => (int)$row['cart_item_id'],
            'type' => 'combination',
            'combination_id' => (int)$row['combination_id'],
            'combination_name' => $row['combination_name'],
            'combination_image' => $row['combination_image'],
            'combination_price' => $combination_price,
            'combination_items' => $combination_items,
            'quantity' => (int)$row['quantity'],
            'total_price' => $total_price,
            'image_url' => $combo_image
        ];
    } else {
        // Đây là sản phẩm đơn lẻ
        $base_price = (float)$row['price'];
        $is_agency_product = (bool)$row['is_agency_product'];
        $platform_fee_rate = (float)$row['platform_fee_rate'];
        
        $final_price = $base_price;
        $platform_fee = 0;
        if ($is_agency_product) {
            $platform_fee = $base_price * ($platform_fee_rate / 100);
            $final_price = $base_price + $platform_fee;
        }
        
        $total_price = $final_price * (int)$row['quantity'];
        
        // Lấy thuộc tính của variant
        $attr_sql = "SELECT a.name as attribute_name, av.value
                     FROM variant_attribute_values vav
                     JOIN attribute_values av ON vav.attribute_value_id = av.id
                     JOIN attributes a ON av.attribute_id = a.id
                     WHERE vav.variant_id = ?";
        $attr_stmt = $conn->prepare($attr_sql);
        $attr_stmt->bind_param("i", $row['variant_id']);
        $attr_stmt->execute();
        $attr_result = $attr_stmt->get_result();
        $attributes = [];
        while ($arow = $attr_result->fetch_assoc()) {
            $attributes[$arow['attribute_name']] = $arow['value'];
        }
        $attr_stmt->close();
        
        $cart[] = [
            'cart_item_id' => (int)$row['cart_item_id'],
            'type' => 'product',
            'product_id' => (int)$row['product_id'],
            'product_name' => $row['product_name'],
            'product_image' => $row['product_image'],
            'variant_id' => (int)$row['variant_id'],
            'attributes' => $attributes,
            'variant_image' => $row['variant_image'],
            'image_url' => !empty($row['variant_image']) ? $row['variant_image'] : $row['product_image'],
            'price' => $final_price,
            'base_price' => $base_price,
            'platform_fee' => $platform_fee,
            'is_agency_product' => $is_agency_product,
            'platform_fee_rate' => $platform_fee_rate,
            'quantity' => (int)$row['quantity'],
            'total_price' => $total_price,
            'stock' => (int)$row['stock']
        ];
    }
}

$stmt->close();
$conn->close();

http_response_code(200);
echo json_encode([
    "success" => true,
    "message" => "Lấy giỏ hàng thành công",
    "data" => $cart
]);
?>