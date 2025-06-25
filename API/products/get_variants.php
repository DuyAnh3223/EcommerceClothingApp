<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../config/db_connect.php';

// Get product_id from query parameters or POST data
$product_id = null;

if ($_SERVER['REQUEST_METHOD'] == 'GET') {
    $product_id = $_GET['product_id'] ?? null;
} else {
    $data = json_decode(file_get_contents("php://input"), true);
    $product_id = $data['product_id'] ?? null;
}

if ($product_id) {
    // Get variants for specific product (dùng bảng trung gian)
    $sql = "SELECT pv.id, pv.color, pv.size, pv.material, pv.price, pv.stock, pv.image_url, pv.status
            FROM product_product_variant ppv
            JOIN product_variants pv ON ppv.product_variant_id = pv.id
            WHERE ppv.product_id = ?
            ORDER BY pv.color, pv.size";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $product_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $variants = [];
    while ($row = $result->fetch_assoc()) {
        $variants[] = [
            'id' => (int)$row['id'],
            'color' => $row['color'],
            'size' => $row['size'],
            'material' => $row['material'],
            'price' => (float)$row['price'],
            'stock' => (int)$row['stock'],
            'image_url' => $row['image_url'],
            'status' => $row['status']
        ];
    }
    $stmt->close();
    
    // Get product info
    $product_stmt = $conn->prepare("SELECT id, name, description, category, gender_target FROM products WHERE id = ?");
    $product_stmt->bind_param("i", $product_id);
    $product_stmt->execute();
    $product_result = $product_stmt->get_result();
    $product_row = $product_result->fetch_assoc();
    $product_stmt->close();
    
    if ($product_row) {
        $product_info = [
            'id' => (int)$product_row['id'],
            'name' => $product_row['name'],
            'description' => $product_row['description'],
            'category' => $product_row['category'],
            'gender_target' => $product_row['gender_target']
        ];
        
        echo json_encode([
            "success" => true,
            "message" => "Lấy danh sách biến thể thành công",
            "product" => $product_info,
            "variants" => $variants,
            "total_variants" => count($variants)
        ]);
    } else {
        echo json_encode([
            "success" => false,
            "message" => "Sản phẩm không tồn tại"
        ]);
    }
    
} else {
    // Get all variants (for admin purposes)
    $sql = "SELECT pv.id, pv.color, pv.size, pv.material, pv.price, pv.stock, pv.image_url, pv.status
            FROM product_variants pv
            ORDER BY pv.id";
    $result = $conn->query($sql);
    
    $variants = [];
    while ($row = $result->fetch_assoc()) {
        $variants[] = [
            'id' => (int)$row['id'],
            'color' => $row['color'],
            'size' => $row['size'],
            'material' => $row['material'],
            'price' => (float)$row['price'],
            'stock' => (int)$row['stock'],
            'image_url' => $row['image_url'],
            'status' => $row['status']
        ];
    }
    
    echo json_encode([
        "success" => true,
        "message" => "Lấy tất cả biến thể thành công",
        "variants" => $variants,
        "total_variants" => count($variants)
    ]);
}

$conn->close();
?>
