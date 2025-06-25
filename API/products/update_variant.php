<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: PUT, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../config/db_connect.php';

$data = json_decode(file_get_contents("php://input"), true);

if (empty($data['product_id']) || empty($data['variant_id'])) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Thiếu product_id hoặc variant_id"
    ]);
    exit();
}

$product_id = (int)$data['product_id'];
$variant_id = (int)$data['variant_id'];

// Bắt đầu transaction
$conn->begin_transaction();

try {
    // Nếu có thay đổi color, size, material thì kiểm tra trùng lặp
    if (isset($data['color']) || isset($data['size']) || isset($data['material'])) {
        // Lấy thông tin hiện tại của biến thể
        $current_variant_stmt = $conn->prepare("SELECT color, size, material FROM product_variants WHERE id = ?");
        $current_variant_stmt->bind_param("i", $variant_id);
        $current_variant_stmt->execute();
        $current_variant_result = $current_variant_stmt->get_result();
        if ($current_variant_result->num_rows === 0) {
            http_response_code(404);
            echo json_encode(["success" => false, "message" => "Biến thể không tồn tại"]);
            exit();
        }
        $current_variant = $current_variant_result->fetch_assoc();
        $current_variant_stmt->close();

        // Xác định giá trị mới cho color, size, material
        $new_color = isset($data['color']) ? trim($data['color']) : $current_variant['color'];
        $new_size = isset($data['size']) ? trim($data['size']) : $current_variant['size'];
        $new_material = isset($data['material']) ? trim($data['material']) : $current_variant['material'];

        // Kiểm tra xem tổ hợp mới đã tồn tại chưa (trừ biến thể hiện tại)
        $duplicate_check = $conn->prepare("SELECT id FROM product_variants WHERE color = ? AND size = ? AND material = ? AND id != ?");
        $duplicate_check->bind_param("sssi", $new_color, $new_size, $new_material, $variant_id);
        $duplicate_check->execute();
        $duplicate_result = $duplicate_check->get_result();
        if ($duplicate_result->num_rows > 0) {
            $duplicate_variant = $duplicate_result->fetch_assoc();
            $duplicate_variant_id = $duplicate_variant['id'];
            $duplicate_check->close();

            // Kiểm tra xem biến thể trùng lặp đã được sử dụng bởi sản phẩm này chưa
            $product_variant_check = $conn->prepare("SELECT * FROM product_product_variant WHERE product_id = ? AND product_variant_id = ?");
            $product_variant_check->bind_param("ii", $product_id, $duplicate_variant_id);
            $product_variant_check->execute();
            $product_variant_result = $product_variant_check->get_result();
            if ($product_variant_result->num_rows > 0) {
                http_response_code(409);
                echo json_encode([
                    "success" => false, 
                    "message" => "Biến thể với màu '$new_color', kích thước '$new_size', chất liệu '$new_material' đã tồn tại cho sản phẩm này"
                ]);
                $product_variant_check->close();
                exit();
            }
            $product_variant_check->close();
        }
        $duplicate_check->close();

        // Cập nhật biến thể hiện có
        $variant_fields = [];
        $variant_params = [];
        $variant_types = '';
        
        if (isset($data['color'])) {
            $variant_fields[] = 'color = ?';
            $variant_params[] = $new_color;
            $variant_types .= 's';
        }
        if (isset($data['size'])) {
            $variant_fields[] = 'size = ?';
            $variant_params[] = $new_size;
            $variant_types .= 's';
        }
        if (isset($data['material'])) {
            $variant_fields[] = 'material = ?';
            $variant_params[] = $new_material;
            $variant_types .= 's';
        }
        
        // Cập nhật biến thể hiện có
        $variant_params[] = $variant_id;
        $variant_types .= 'i';
        $variant_sql = "UPDATE product_variants SET " . implode(", ", $variant_fields) . " WHERE id = ?";
        $variant_stmt = $conn->prepare($variant_sql);
        $variant_stmt->bind_param($variant_types, ...$variant_params);
        $variant_stmt->execute();
        $variant_stmt->close();
    }
    
    // Cập nhật thông tin trong bảng product_product_variant
    $fields = [];
    $params = [];
    $types = '';
    
    if (isset($data['price'])) {
        $fields[] = 'price = ?';
        $params[] = (float)$data['price'];
        $types .= 'd';
    }
    if (isset($data['stock'])) {
        $fields[] = 'stock = ?';
        $params[] = (int)$data['stock'];
        $types .= 'i';
    }
    if (isset($data['image_url'])) {
        $fields[] = 'image_url = ?';
        $params[] = trim($data['image_url']);
        $types .= 's';
    }
    if (isset($data['status'])) {
        $fields[] = 'status = ?';
        $params[] = trim($data['status']);
        $types .= 's';
    }
    
    if (!empty($fields)) {
        $params[] = $product_id;
        $params[] = $variant_id;
        $types .= 'ii';
        $sql = "UPDATE product_product_variant SET " . implode(", ", $fields) . " WHERE product_id = ? AND product_variant_id = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param($types, ...$params);
        $stmt->execute();
        $stmt->close();
    }
    
    // Commit transaction
    $conn->commit();
    
    http_response_code(200);
    echo json_encode([
        "success" => true,
        "message" => "Cập nhật biến thể thành công"
    ]);
    
} catch (Exception $e) {
    // Rollback transaction nếu có lỗi
    $conn->rollback();
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Lỗi khi cập nhật biến thể: " . $e->getMessage()
    ]);
}

$conn->close();
