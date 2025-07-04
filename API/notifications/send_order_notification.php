<?php
require_once '../config/config.php';
require_once '../utils/response.php';

// Set CORS headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(false, 'Method not allowed', null, 405);
    exit();
}

try {
    $conn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);
    
    if ($conn->connect_error) {
        sendResponse(false, 'Connection failed: ' . $conn->connect_error, null, 500);
        exit();
    }
    
    // Get JSON input
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input) {
        sendResponse(false, 'Invalid JSON input', null, 400);
        exit();
    }
    
    $orderId = $input['order_id'] ?? null;
    $status = $input['status'] ?? null;
    
    if (!$orderId || !$status) {
        sendResponse(false, 'Order ID and status are required', null, 400);
        exit();
    }
    
    // Get order details
    $orderSql = "SELECT o.*, u.username FROM orders o 
                 JOIN users u ON o.user_id = u.id 
                 WHERE o.id = ?";
    $orderStmt = $conn->prepare($orderSql);
    $orderStmt->bind_param("i", $orderId);
    $orderStmt->execute();
    $orderResult = $orderStmt->get_result();
    $order = $orderResult->fetch_assoc();
    
    if (!$order) {
        sendResponse(false, 'Order not found', null, 404);
        exit();
    }
    
    $userId = $order['user_id'];
    $username = $order['username'];
    $totalAmount = $order['total_amount'];
    
    // Create notification based on status
    $title = '';
    $content = '';
    $type = 'order_status';
    
    switch ($status) {
        case 'confirmed':
            $title = 'Đơn hàng đã được xác nhận';
            $content = "Đơn hàng #$orderId của bạn đã được xác nhận và đang được xử lý. Tổng tiền: " . number_format($totalAmount) . " VNĐ <=> BACoin";
            break;
        case 'shipping':
            $title = 'Đơn hàng đang được giao';
            $content = "Đơn hàng #$orderId của bạn đang được giao đến địa chỉ của bạn. Dự kiến giao trong 1-3 ngày.";
            break;
        case 'delivered':
            $title = 'Đơn hàng đã được giao thành công';
            $content = "Đơn hàng #$orderId đã được giao thành công. Cảm ơn bạn đã mua hàng!";
            break;
        case 'cancelled':
            $title = 'Đơn hàng đã bị hủy';
            $content = "Đơn hàng #$orderId đã bị hủy. Nếu có thắc mắc, vui lòng liên hệ với chúng tôi.";
            break;
        default:
            $title = 'Cập nhật trạng thái đơn hàng';
            $content = "Đơn hàng #$orderId đã được cập nhật trạng thái thành: $status";
    }
    
    // Insert notification
    $sql = "INSERT INTO notifications (user_id, title, content, type, is_read) VALUES (?, ?, ?, ?, 0)";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("isss", $userId, $title, $content, $type);
    $result = $stmt->execute();
    
    if ($result) {
        $notificationId = $conn->insert_id;
        $stmt->close();
        $orderStmt->close();
        $conn->close();
        
        sendResponse(true, 'Order notification sent successfully', [
            'notification_id' => $notificationId,
            'user_id' => $userId,
            'username' => $username,
            'title' => $title,
            'content' => $content,
            'type' => $type
        ]);
    } else {
        sendResponse(false, 'Failed to send order notification', null, 500);
    }
    
} catch (Exception $e) {
    sendResponse(false, 'Server error: ' . $e->getMessage(), null, 500);
}
?> 