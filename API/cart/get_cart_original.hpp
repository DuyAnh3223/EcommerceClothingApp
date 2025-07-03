
<!-- <?php
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

$sql = "SELECT ci.id AS cart_item_id, ci.product_id, p.name as product_name, p.main_image as product_image, ci.variant_id, pv.price, pv.stock, pv.image_url as variant_image, ci.quantity, p.is_agency_product, p.platform_fee_rate
        FROM cart_items ci
        JOIN products p ON ci.product_id = p.id
        JOIN product_variant pv ON ci.product_id = pv.product_id AND ci.variant_id = pv.variant_id
        WHERE ci.user_id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $user_id);
$stmt->execute();
$result = $stmt->get_result();
$cart = [];
while ($row = $result->fetch_assoc()) {
    // Tính toán giá cuối cùng với phí sàn cho sản phẩm agency
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
    
    // Lấy thuộc tính của variant, trả về dạng object
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
$stmt->close();
$conn->close();

http_response_code(200);
echo json_encode([
    "success" => true,
    "message" => "Lấy giỏ hàng thành công",
    "data" => $cart
]); -->


