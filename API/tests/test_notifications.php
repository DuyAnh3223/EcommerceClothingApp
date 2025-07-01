<?php
require_once 'config/config.php';
require_once 'utils/response.php';

// Set CORS headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    $conn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);
    
    if ($conn->connect_error) {
        sendResponse(false, 'Connection failed: ' . $conn->connect_error, null, 500);
        exit();
    }
    
    if ($_SERVER['REQUEST_METHOD'] === 'GET') {
        // Get all notifications
        $sql = "SELECT n.*, u.username FROM notifications n 
                JOIN users u ON n.user_id = u.id 
                ORDER BY n.created_at DESC";
        $result = $conn->query($sql);
        
        $notifications = [];
        while ($row = $result->fetch_assoc()) {
            $notifications[] = [
                'id' => (int)$row['id'],
                'user_id' => (int)$row['user_id'],
                'username' => $row['username'],
                'title' => $row['title'],
                'content' => $row['content'],
                'type' => $row['type'],
                'is_read' => (bool)$row['is_read'],
                'created_at' => $row['created_at']
            ];
        }
        
        sendResponse(true, 'Notifications retrieved successfully', $notifications);
        
    } elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
        // Add sample notifications
        $input = json_decode(file_get_contents('php://input'), true);
        $action = $input['action'] ?? 'add_samples';
        
        if ($action === 'add_samples') {
            // Get user IDs
            $userSql = "SELECT id FROM users WHERE role = 'user' LIMIT 3";
            $userResult = $conn->query($userSql);
            $userIds = [];
            while ($row = $userResult->fetch_assoc()) {
                $userIds[] = $row['id'];
            }
            
            if (empty($userIds)) {
                sendResponse(false, 'No users found', null, 404);
                exit();
            }
            
            // Sample notifications
            $sampleNotifications = [
                [
                    'title' => 'Chào mừng bạn đến với ứng dụng!',
                    'content' => 'Cảm ơn bạn đã đăng ký. Chúng tôi hy vọng bạn sẽ có trải nghiệm mua sắm tuyệt vời.',
                    'type' => 'other'
                ],
                [
                    'title' => 'Khuyến mãi cuối tuần',
                    'content' => 'Giảm giá 20% cho tất cả sản phẩm áo thun. Chỉ diễn ra trong 2 ngày!',
                    'type' => 'sale'
                ],
                [
                    'title' => 'Voucher sinh nhật',
                    'content' => 'Chúc mừng sinh nhật! Bạn nhận được voucher giảm giá 50.000 VNĐ cho đơn hàng tiếp theo.',
                    'type' => 'voucher'
                ],
                [
                    'title' => 'Đơn hàng đã được xác nhận',
                    'content' => 'Đơn hàng #123 của bạn đã được xác nhận và đang được xử lý.',
                    'type' => 'order_status'
                ],
                [
                    'title' => 'Sản phẩm mới',
                    'content' => 'Bộ sưu tập mùa hè 2024 đã có mặt. Khám phá ngay các sản phẩm mới nhất!',
                    'type' => 'sale'
                ]
            ];
            
            $insertedCount = 0;
            foreach ($userIds as $userId) {
                foreach ($sampleNotifications as $notification) {
                    $sql = "INSERT INTO notifications (user_id, title, content, type, is_read) VALUES (?, ?, ?, ?, 0)";
                    $stmt = $conn->prepare($sql);
                    $stmt->bind_param("isss", $userId, $notification['title'], $notification['content'], $notification['type']);
                    
                    if ($stmt->execute()) {
                        $insertedCount++;
                    }
                    $stmt->close();
                }
            }
            
            $conn->close();
            sendResponse(true, "Added $insertedCount sample notifications", [
                'inserted_count' => $insertedCount,
                'users_count' => count($userIds),
                'notifications_per_user' => count($sampleNotifications)
            ]);
            
        } elseif ($action === 'clear_all') {
            // Clear all notifications
            $sql = "DELETE FROM notifications";
            $result = $conn->query($sql);
            
            $conn->close();
            sendResponse(true, 'All notifications cleared successfully', [
                'affected_rows' => $conn->affected_rows
            ]);
        }
    }
    
} catch (Exception $e) {
    sendResponse(false, 'Server error: ' . $e->getMessage(), null, 500);
}
?> 