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

if (!empty($data['variant_id'])) {
    $variant_id = $data['variant_id'];
    $color = $data['color'] ?? null;
    $size = $data['size'] ?? null;
    $material = $data['material'] ?? null;
    $price = $data['price'] ?? null;
    $stock = $data['stock'] ?? null;
    $image_url = $data['image_url'] ?? null;
    $status = $data['status'] ?? null;
    
    // Check if variant exists
    $check_stmt = $conn->prepare("SELECT id FROM product_variants WHERE id = ?");
    $check_stmt->bind_param("i", $variant_id);
    $check_stmt->execute();
    $result = $check_stmt->get_result();
    
    if ($result->num_rows === 0) {
        echo json_encode(["success" => false, "message" => "Biến thể không tồn tại"]);
        $check_stmt->close();
        exit();
    }
    
    $check_stmt->close();
    
    // Get current variant data to merge with updates
    $current_stmt = $conn->prepare("SELECT color, size, material, price, stock, image_url, status FROM product_variants WHERE id = ?");
    $current_stmt->bind_param("i", $variant_id);
    $current_stmt->execute();
    $current_result = $current_stmt->get_result();
    $current_data = $current_result->fetch_assoc();
    $current_stmt->close();
    
    // Use provided values or keep current values
    $color = $color ?? $current_data['color'];
    $size = $size ?? $current_data['size'];
    $material = $material ?? $current_data['material'];
    $price = $price ?? $current_data['price'];
    $stock = $stock ?? $current_data['stock'];
    $image_url = $image_url ?? $current_data['image_url'];
    $status = $status ?? $current_data['status'];
    
    // Update variant
    $stmt = $conn->prepare("UPDATE product_variants SET color = ?, size = ?, material = ?, price = ?, stock = ?, image_url = ?, status = ? WHERE id = ?");
    $stmt->bind_param("sssdissi", $color, $size, $material, $price, $stock, $image_url, $status, $variant_id);
    
    if ($stmt->execute()) {
        echo json_encode([
            "success" => true, 
            "message" => "Cập nhật biến thể thành công",
            "variant_id" => $variant_id,
            "updated_data" => [
                "color" => $color,
                "size" => $size,
                "material" => $material,
                "price" => $price,
                "stock" => $stock,
                "image_url" => $image_url,
                "status" => $status
            ]
        ]);
    } else {
        echo json_encode(["success" => false, "message" => "Lỗi: " . $conn->error]);
    }
    
    $stmt->close();
    
} else {
    echo json_encode(["success" => false, "message" => "Thiếu variant_id"]);
}

$conn->close();
?>
