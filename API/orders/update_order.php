<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");
require_once '../config/db_connect.php';

if (
    $_SERVER['REQUEST_METHOD'] == 'OPTIONS'
) {
    http_response_code(200);
    exit();
}

$data = json_decode(file_get_contents("php://input"), true);

$order_id = $data['order_id'] ?? null;
$status = $data['status'] ?? null;

if (!$order_id || !$status) {
    echo json_encode(["success" => false, "message" => "Thiếu order_id hoặc status"]);
    exit();
}

$stmt = $conn->prepare("UPDATE orders SET status = ? WHERE id = ?");
$stmt->bind_param("si", $status, $order_id);

if ($stmt->execute()) {
    // Send notification to user about order status change
    $notificationData = json_encode([
        'order_id' => $order_id,
        'status' => $status
    ]);
    
    $notificationUrl = 'http://127.0.0.1/EcommerceClothingApp/API/notifications/send_order_notification.php';
    $notificationContext = stream_context_create([
        'http' => [
            'method' => 'POST',
            'header' => 'Content-Type: application/json',
            'content' => $notificationData
        ]
    ]);
    
    // Send notification asynchronously (don't wait for response)
    @file_get_contents($notificationUrl, false, $notificationContext);
    
    echo json_encode(["success" => true, "message" => "Cập nhật trạng thái đơn hàng thành công"]);
} else {
    echo json_encode(["success" => false, "message" => "Lỗi: " . $conn->error]);
}
$stmt->close();
$conn->close();
?>