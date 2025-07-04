<?php
require_once '../config/db_connect.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    // Bắt đầu transaction
    $conn->begin_transaction();
    
    // Lấy danh sách đơn hàng BACoin đã thanh toán nhưng chưa được xác nhận
    $sql = "SELECT 
                o.id as order_id,
                o.status as order_status,
                o.created_at,
                p.status as payment_status,
                p.paid_at
            FROM orders o
            JOIN payments p ON o.id = p.order_id
            WHERE p.payment_method = 'BACoin' 
            AND p.status = 'paid' 
            AND o.status = 'pending'";
    
    $result = $conn->query($sql);
    
    $updated_orders = [];
    $update_count = 0;
    
    while ($row = $result->fetch_assoc()) {
        $order_id = $row['order_id'];
        $order_status = $row['order_status'];
        $created_at = $row['created_at'];
        $payment_status = $row['payment_status'];
        $paid_at = $row['paid_at'];
        
        // Cập nhật trạng thái đơn hàng thành confirmed
        $update_sql = "UPDATE orders SET status = 'confirmed', updated_at = NOW() WHERE id = ?";
        $update_stmt = $conn->prepare($update_sql);
        $update_stmt->bind_param("i", $order_id);
        
        if ($update_stmt->execute()) {
            $update_count++;
            $updated_orders[] = [
                'order_id' => (int)$order_id,
                'old_status' => $order_status,
                'new_status' => 'confirmed',
                'created_at' => $created_at,
                'payment_status' => $payment_status,
                'paid_at' => $paid_at,
                'updated_at' => date('Y-m-d H:i:s')
            ];
        }
        
        $update_stmt->close();
    }
    
    // Commit transaction
    $conn->commit();
    
    // Lấy thống kê sau khi cập nhật
    $total_bacoin_orders_sql = "SELECT COUNT(*) as total FROM orders o JOIN payments p ON o.id = p.order_id WHERE p.payment_method = 'BACoin'";
    $total_result = $conn->query($total_bacoin_orders_sql);
    $total_bacoin_orders = $total_result->fetch_assoc()['total'];
    
    $confirmed_bacoin_orders_sql = "SELECT COUNT(*) as total FROM orders o JOIN payments p ON o.id = p.order_id WHERE p.payment_method = 'BACoin' AND o.status = 'confirmed'";
    $confirmed_result = $conn->query($confirmed_bacoin_orders_sql);
    $confirmed_bacoin_orders = $confirmed_result->fetch_assoc()['total'];
    
    $pending_bacoin_orders_sql = "SELECT COUNT(*) as total FROM orders o JOIN payments p ON o.id = p.order_id WHERE p.payment_method = 'BACoin' AND o.status = 'pending'";
    $pending_result = $conn->query($pending_bacoin_orders_sql);
    $pending_bacoin_orders = $pending_result->fetch_assoc()['total'];
    
    // Kiểm tra xem còn đơn hàng nào chưa được cập nhật không
    $remaining_inconsistent_sql = "SELECT COUNT(*) as total FROM orders o JOIN payments p ON o.id = p.order_id WHERE p.payment_method = 'BACoin' AND p.status = 'paid' AND o.status = 'pending'";
    $remaining_result = $conn->query($remaining_inconsistent_sql);
    $remaining_inconsistent = $remaining_result->fetch_assoc()['total'];
    
    echo json_encode([
        'success' => true,
        'message' => "Đã cập nhật trạng thái cho $update_count đơn hàng BACoin",
        'updated_orders' => $updated_orders,
        'statistics' => [
            'total_bacoin_orders' => (int)$total_bacoin_orders,
            'confirmed_orders' => (int)$confirmed_bacoin_orders,
            'pending_orders' => (int)$pending_bacoin_orders,
            'confirmation_rate' => $total_bacoin_orders > 0 ? round(($confirmed_bacoin_orders / $total_bacoin_orders) * 100, 2) : 0,
            'updated_count' => $update_count,
            'remaining_inconsistent' => (int)$remaining_inconsistent
        ],
        'summary' => [
            'orders_updated' => $update_count,
            'all_consistent' => $remaining_inconsistent === 0,
            'recommendation' => $remaining_inconsistent === 0 ? 
                'Tất cả đơn hàng BACoin đã được cập nhật đúng trạng thái.' : 
                "Vẫn còn $remaining_inconsistent đơn hàng chưa được cập nhật."
        ]
    ]);
    
} catch (Exception $e) {
    // Rollback nếu có lỗi
    $conn->rollback();
    
    echo json_encode([
        'success' => false,
        'message' => 'Server error: ' . $e->getMessage()
    ]);
}

$conn->close();
?> 