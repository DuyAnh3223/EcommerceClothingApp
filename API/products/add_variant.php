<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../config/db_connect.php';

$data = json_decode(file_get_contents("php://input"), true);

if (!empty($data['product_id'])) {
    $product_id = $data['product_id'];
    $color = $data['color'] ?? '';
    $size = $data['size'] ?? '';
    $material = $data['material'] ?? '';
    $price = $data['price'] ?? 0;
    $stock = $data['stock'] ?? 0;
    $image_url = $data['image_url'] ?? '';
    $status = $data['status'] ?? 'active';

    // Validate product_id exists
    $check_stmt = $conn->prepare("SELECT id FROM products WHERE id = ?");
    $check_stmt->bind_param("i", $product_id);
    $check_stmt->execute();
    $result = $check_stmt->get_result();
    if ($result->num_rows === 0) {
        echo json_encode(["success" => false, "message" => "Sản phẩm không tồn tại"]);
        $check_stmt->close();
        exit();
    }
    $check_stmt->close();

    // Thêm biến thể vào bảng product_variants
    $stmt = $conn->prepare("INSERT INTO product_variants (color, size, material, price, stock, image_url, status) VALUES (?, ?, ?, ?, ?, ?, ?)");
    $stmt->bind_param("sssdiis", $color, $size, $material, $price, $stock, $image_url, $status);
    if ($stmt->execute()) {
        $variant_id = $conn->insert_id;
        // Thêm liên kết vào bảng product_product_variant
        $link_stmt = $conn->prepare("INSERT INTO product_product_variant (product_id, product_variant_id) VALUES (?, ?)");
        $link_stmt->bind_param("ii", $product_id, $variant_id);
        if ($link_stmt->execute()) {
            echo json_encode([
                "success" => true,
                "message" => "Thêm biến thể sản phẩm thành công",
                "variant_id" => $variant_id,
                "product_id" => $product_id
            ]);
        } else {
            // Nếu lỗi khi thêm vào bảng trung gian, rollback biến thể
            $conn->query("DELETE FROM product_variants WHERE id = $variant_id");
            echo json_encode(["success" => false, "message" => "Lỗi khi liên kết sản phẩm và biến thể: " . $link_stmt->error]);
        }
        $link_stmt->close();
    } else {
        echo json_encode(["success" => false, "message" => "Lỗi: " . $conn->error]);
    }
    $stmt->close();
} else {
    echo json_encode(["success" => false, "message" => "Thiếu product_id"]);
}

$conn->close();
?>
