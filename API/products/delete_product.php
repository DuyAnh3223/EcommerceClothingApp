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
$product_id = $data['id'] ?? null;

if ($product_id) {
    // Check if product exists
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
    
    // Start transaction
    $conn->begin_transaction();
    
    try {
        // Delete product (variants will be deleted automatically due to CASCADE)
        $stmt = $conn->prepare("DELETE FROM products WHERE id = ?");
        $stmt->bind_param("i", $product_id);

        if ($stmt->execute()) {
            $conn->commit();
            echo json_encode(["success" => true, "message" => "Xóa sản phẩm thành công"]);
        } else {
            throw new Exception("Lỗi khi xóa sản phẩm: " . $conn->error);
        }
        $stmt->close();
        
    } catch (Exception $e) {
        $conn->rollback();
        echo json_encode(["success" => false, "message" => $e->getMessage()]);
    }
    
} else {
    echo json_encode(["success" => false, "message" => "Thiếu ID sản phẩm"]);
}

$conn->close();
?> 