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
    // Lấy danh sách đơn hàng thanh toán bằng BACoin
    $sql = "SELECT 
                o.id as order_id,
                o.user_id,
                o.total_amount,
                o.status as order_status,
                o.created_at,
                o.updated_at,
                p.id as payment_id,
                p.payment_method,
                p.amount,
                p.status as payment_status,
                p.transaction_code,
                p.paid_at,
                p.amount_bacoin,
                u.username,
                u.email
            FROM orders o
            JOIN payments p ON o.id = p.order_id
            JOIN users u ON o.user_id = u.id
            WHERE p.payment_method = 'BACoin'
            ORDER BY o.id DESC
            LIMIT 20";
    
    $result = $conn->query($sql);
    
    $bacoin_orders = [];
    $status_stats = [
        'pending' => 0,
        'confirmed' => 0,
        'shipping' => 0,
        'delivered' => 0,
        'cancelled' => 0
    ];
    
    while ($row = $result->fetch_assoc()) {
        $bacoin_orders[] = [
            'order_id' => (int)$row['order_id'],
            'user_id' => (int)$row['user_id'],
            'username' => $row['username'],
            'email' => $row['email'],
            'total_amount' => (float)$row['total_amount'],
            'order_status' => $row['order_status'],
            'created_at' => $row['created_at'],
            'updated_at' => $row['updated_at'],
            'payment_id' => (int)$row['payment_id'],
            'payment_method' => $row['payment_method'],
            'payment_status' => $row['payment_status'],
            'transaction_code' => $row['transaction_code'],
            'paid_at' => $row['paid_at'],
            'amount_bacoin' => (float)$row['amount_bacoin']
        ];
        
        // Thống kê trạng thái
        $status_stats[$row['order_status']]++;
    }
    
    // Lấy thống kê tổng quan
    $total_bacoin_orders_sql = "SELECT COUNT(*) as total FROM orders o JOIN payments p ON o.id = p.order_id WHERE p.payment_method = 'BACoin'";
    $total_result = $conn->query($total_bacoin_orders_sql);
    $total_bacoin_orders = $total_result->fetch_assoc()['total'];
    
    $confirmed_bacoin_orders_sql = "SELECT COUNT(*) as total FROM orders o JOIN payments p ON o.id = p.order_id WHERE p.payment_method = 'BACoin' AND o.status = 'confirmed'";
    $confirmed_result = $conn->query($confirmed_bacoin_orders_sql);
    $confirmed_bacoin_orders = $confirmed_result->fetch_assoc()['total'];
    
    $pending_bacoin_orders_sql = "SELECT COUNT(*) as total FROM orders o JOIN payments p ON o.id = p.order_id WHERE p.payment_method = 'BACoin' AND o.status = 'pending'";
    $pending_result = $conn->query($pending_bacoin_orders_sql);
    $pending_bacoin_orders = $pending_result->fetch_assoc()['total'];
    
    // Kiểm tra các đơn hàng BACoin có payment_status = 'paid' nhưng order_status = 'pending'
    $inconsistent_sql = "SELECT 
                            o.id as order_id,
                            o.status as order_status,
                            p.status as payment_status,
                            p.paid_at
                        FROM orders o
                        JOIN payments p ON o.id = p.order_id
                        WHERE p.payment_method = 'BACoin' 
                        AND p.status = 'paid' 
                        AND o.status = 'pending'";
    $inconsistent_result = $conn->query($inconsistent_sql);
    
    $inconsistent_orders = [];
    while ($row = $inconsistent_result->fetch_assoc()) {
        $inconsistent_orders[] = [
            'order_id' => (int)$row['order_id'],
            'order_status' => $row['order_status'],
            'payment_status' => $row['payment_status'],
            'paid_at' => $row['paid_at']
        ];
    }
    
    echo json_encode([
        'success' => true,
        'message' => 'BACoin order status test completed successfully',
        'bacoin_orders' => $bacoin_orders,
        'statistics' => [
            'total_bacoin_orders' => (int)$total_bacoin_orders,
            'confirmed_orders' => (int)$confirmed_bacoin_orders,
            'pending_orders' => (int)$pending_bacoin_orders,
            'confirmation_rate' => $total_bacoin_orders > 0 ? round(($confirmed_bacoin_orders / $total_bacoin_orders) * 100, 2) : 0,
            'status_distribution' => $status_stats
        ],
        'inconsistent_orders' => $inconsistent_orders,
        'has_inconsistency' => count($inconsistent_orders) > 0,
        'recommendation' => count($inconsistent_orders) > 0 ? 
            'Có ' . count($inconsistent_orders) . ' đơn hàng BACoin đã thanh toán nhưng chưa được xác nhận. Cần cập nhật trạng thái.' : 
            'Tất cả đơn hàng BACoin đã được xử lý đúng.'
    ]);
    
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Server error: ' . $e->getMessage()
    ]);
}

$conn->close();
?> 