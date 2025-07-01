<?php
require_once 'config/config.php';
require_once 'utils/response.php';

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
    
    // Test the order detail API
    $orderId = 21; // Test with order ID 21
    
    // Get order details with user and address information
    $sql = "SELECT o.id, o.user_id, o.address_id, o.order_date, o.total_amount, o.status, o.created_at, o.updated_at,
                   u.username, u.email, u.phone,
                   ua.address_line, ua.city, ua.province, ua.postal_code
            FROM orders o
            JOIN users u ON o.user_id = u.id
            JOIN user_addresses ua ON o.address_id = ua.id
            WHERE o.id = ?";
    
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $orderId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        sendResponse(false, 'Order not found', null, 404);
        exit();
    }
    
    $order = $result->fetch_assoc();
    $stmt->close();
    
    // Get order items
    $items_sql = "SELECT oi.id, oi.product_id, oi.variant_id, oi.quantity, oi.price,
                         pv.image_url,
                         p.name as product_name
                  FROM order_items oi
                  JOIN product_variant pv ON oi.product_id = pv.product_id AND oi.variant_id = pv.variant_id
                  JOIN products p ON oi.product_id = p.id
                  WHERE oi.order_id = ?";
    
    $stmt = $conn->prepare($items_sql);
    $stmt->bind_param("i", $orderId);
    $stmt->execute();
    $items_result = $stmt->get_result();
    
    $items = [];
    while ($item = $items_result->fetch_assoc()) {
        // Get variant attributes
        $variant_attrs = [];
        $sql_attr = "SELECT av.value, a.name
                     FROM variant_attribute_values vav
                     JOIN attribute_values av ON vav.attribute_value_id = av.id
                     JOIN attributes a ON av.attribute_id = a.id
                     WHERE vav.variant_id = ?";
        $stmt_attr = $conn->prepare($sql_attr);
        $stmt_attr->bind_param("i", $item['variant_id']);
        $stmt_attr->execute();
        $result_attr = $stmt_attr->get_result();
        while ($attr = $result_attr->fetch_assoc()) {
            $variant_attrs[] = $attr['name'] . ': ' . $attr['value'];
        }
        $stmt_attr->close();
        $variant_str = implode(', ', $variant_attrs);

        $items[] = [
            'id' => (int)$item['id'],
            'product_id' => (int)$item['product_id'],
            'variant_id' => (int)$item['variant_id'],
            'quantity' => (int)$item['quantity'],
            'price' => (float)$item['price'],
            'image_url' => $item['image_url'],
            'product_name' => $item['product_name'],
            'variant' => $variant_str
        ];
    }
    $stmt->close();
    
    // Get payment information
    $payment_sql = "SELECT id, payment_method, amount, status, transaction_code, paid_at
                    FROM payments 
                    WHERE order_id = ?";
    $stmt = $conn->prepare($payment_sql);
    $stmt->bind_param("i", $orderId);
    $stmt->execute();
    $payment_result = $stmt->get_result();
    
    $payments = [];
    while ($payment = $payment_result->fetch_assoc()) {
        $payments[] = [
            'id' => (int)$payment['id'],
            'payment_method' => $payment['payment_method'],
            'amount' => (float)$payment['amount'],
            'status' => $payment['status'],
            'transaction_code' => $payment['transaction_code'],
            'paid_at' => $payment['paid_at']
        ];
    }
    $stmt->close();
    
    $order_data = [
        'id' => (int)$order['id'],
        'user_id' => (int)$order['user_id'],
        'address_id' => (int)$order['address_id'],
        'order_date' => $order['order_date'],
        'total_amount' => (float)$order['total_amount'],
        'status' => $order['status'],
        'created_at' => $order['created_at'],
        'updated_at' => $order['updated_at'],
        'username' => $order['username'],
        'email' => $order['email'],
        'phone' => $order['phone'],
        'address_line' => $order['address_line'],
        'city' => $order['city'],
        'province' => $order['province'],
        'postal_code' => $order['postal_code'],
        'items' => $items,
        'payments' => $payments
    ];

    sendResponse(true, 'Order detail test completed successfully', [
        'order_detail' => $order_data,
        'test_info' => [
            'order_id' => $orderId,
            'total_items' => count($items),
            'total_payments' => count($payments),
            'order_status' => $order['status'],
            'show_payment_section' => in_array($order['status'], ['confirmed', 'shipping', 'delivered'])
        ]
    ]);
    
} catch (Exception $e) {
    sendResponse(false, 'Server error: ' . $e->getMessage(), null, 500);
}
?> 