<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");
require_once '../config/db_connect.php';

$data = json_decode(file_get_contents("php://input"), true);

$order_id = $data['order_id'] ?? null;

if (!$order_id) {
    echo json_encode(["success" => false, "message" => "Thiếu order_id"]);
    exit();
}

// Bắt đầu transaction
$conn->begin_transaction();

try {
    // Cập nhật trạng thái đơn hàng thành cancelled
    $stmt = $conn->prepare("UPDATE orders SET status = 'cancelled' WHERE id = ?");
    $stmt->bind_param("i", $order_id);
    $stmt->execute();
    $stmt->close();

    // Cập nhật trạng thái thanh toán thành failed
    $payment_stmt = $conn->prepare("UPDATE payments SET status = 'failed' WHERE order_id = ?");
    $payment_stmt->bind_param("i", $order_id);
    $payment_stmt->execute();
    $payment_stmt->close();

    // Commit transaction
    $conn->commit();

    echo json_encode([
        "success" => true, 
        "message" => "Đã hủy đơn hàng và cập nhật trạng thái thanh toán"
    ]);

} catch (Exception $e) {
    // Rollback transaction nếu có lỗi
    $conn->rollback();
    echo json_encode([
        "success" => false, 
        "message" => "Lỗi: " . $e->getMessage()
    ]);
}

$conn->close();
?>