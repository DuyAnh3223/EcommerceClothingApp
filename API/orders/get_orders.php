<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../config/db_connect.php';

try {
    $sql = "SELECT o.id, o.user_id, o.address_id, o.order_date, o.total_amount, o.status, o.created_at, o.updated_at,
                   u.username, u.email, u.phone,
                   ua.address_line, ua.city, ua.province
            FROM orders o
            JOIN users u ON o.user_id = u.id
            JOIN user_addresses ua ON o.address_id = ua.id
            ORDER BY o.created_at DESC";
    
    $result = $conn->query($sql);

    $orders = [];
    while ($row = $result->fetch_assoc()) {
        // Get order items for each order
        $order_id = (int)$row['id'];
        $items_sql = "SELECT oi.id, oi.product_id, oi.variant_id, oi.quantity, oi.price,
                             pv.image_url,
                             p.name as product_name
                      FROM order_items oi
                      JOIN product_variant pv ON oi.product_id = pv.product_id AND oi.variant_id = pv.variant_id
                      JOIN products p ON oi.product_id = p.id
                      WHERE oi.order_id = ?";
        
        $stmt = $conn->prepare($items_sql);
        $stmt->bind_param("i", $order_id);
        $stmt->execute();
        $items_result = $stmt->get_result();
        
        $items = [];
        while ($item = $items_result->fetch_assoc()) {
            // Lấy thuộc tính variant
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
        
        $orders[] = [
            'id' => (int)$row['id'],
            'user_id' => (int)$row['user_id'],
            'address_id' => (int)$row['address_id'],
            'order_date' => $row['order_date'],
            'total_amount' => (float)$row['total_amount'],
            'status' => $row['status'],
            'created_at' => $row['created_at'],
            'updated_at' => $row['updated_at'],
            'username' => $row['username'],
            'email' => $row['email'],
            'phone' => $row['phone'],
            'address_line' => $row['address_line'],
            'city' => $row['city'],
            'province' => $row['province'],
            'items' => $items
        ];
    }

    echo json_encode([
        "success" => true,
        "message" => "Lấy danh sách đơn hàng thành công",
        "data" => $orders
    ]);

} catch (Exception $e) {
    echo json_encode([
        "success" => false,
        "message" => "Lỗi: " . $e->getMessage()
    ]);
}

$conn->close();
?>
