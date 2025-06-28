<?php
require_once '../config/config.php';
require_once '../utils/response.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    sendResponse(false, 'Method not allowed', null, 405);
    exit();
}

$userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
$page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
$limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 20;

if (!$userId) {
    sendResponse(false, 'User ID is required', null, 400);
    exit();
}

$offset = ($page - 1) * $limit;

$conn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);
if ($conn->connect_error) {
    sendResponse(false, 'Connection failed: ' . $conn->connect_error, null, 500);
    exit();
}

$sql = "SELECT p.id, p.order_id, p.payment_method, p.amount, p.status, p.transaction_code, p.paid_at, o.order_date, o.total_amount
        FROM payments p
        JOIN orders o ON p.order_id = o.id
        WHERE o.user_id = ?
        ORDER BY p.id DESC
        LIMIT ? OFFSET ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("iii", $userId, $limit, $offset);
$stmt->execute();
$result = $stmt->get_result();

$payments = [];
while ($row = $result->fetch_assoc()) {
    // Lấy danh sách sản phẩm đã mua trong order này
    $orderId = (int)$row['order_id'];
    $products = [];
    $sql_items = "SELECT oi.*, 
                         pr.name as product_name, 
                         pr.main_image, 
                         v.sku, 
                         pv.image_url as variant_image
                  FROM order_items oi
                  JOIN products pr ON oi.product_id = pr.id
                  JOIN variants v ON oi.variant_id = v.id
                  LEFT JOIN product_variant pv ON oi.product_id = pv.product_id AND oi.variant_id = pv.variant_id
                  WHERE oi.order_id = ?";
    $stmt_items = $conn->prepare($sql_items);
    $stmt_items->bind_param("i", $orderId);
    $stmt_items->execute();
    $result_items = $stmt_items->get_result();
    while ($item = $result_items->fetch_assoc()) {
        // Lấy thuộc tính variant (color, size, brand...)
        $sql_attr = "SELECT av.value, a.name
                     FROM variant_attribute_values vav
                     JOIN attribute_values av ON vav.attribute_value_id = av.id
                     JOIN attributes a ON av.attribute_id = a.id
                     WHERE vav.variant_id = ?";
        $stmt_attr = $conn->prepare($sql_attr);
        $stmt_attr->bind_param("i", $item['variant_id']);
        $stmt_attr->execute();
        $result_attr = $stmt_attr->get_result();
        $variant_attrs = [];
        while ($attr = $result_attr->fetch_assoc()) {
            $variant_attrs[] = $attr['name'] . ': ' . $attr['value'];
        }
        $variant_str = implode(', ', $variant_attrs);
        $stmt_attr->close();

        // Ưu tiên ảnh variant, nếu không có thì lấy ảnh sản phẩm
        $image_url = $item['variant_image'] ? $item['variant_image'] : $item['main_image'];
        if ($image_url) {
            $image_url = 'http://127.0.0.1/EcommerceClothingApp/API/uploads/' . $image_url;
        } else {
            $image_url = '';
        }

        $products[] = [
            'product_id' => (int)$item['product_id'],
            'name' => $item['product_name'],
            'variant' => $variant_str,
            'image' => $image_url,
            'quantity' => (int)$item['quantity'],
            'price' => (float)$item['price']
        ];
    }
    $stmt_items->close();

    $payments[] = [
        'id' => (int)$row['id'],
        'order_id' => (int)$row['order_id'],
        'payment_method' => $row['payment_method'],
        'amount' => (float)$row['amount'],
        'status' => $row['status'],
        'transaction_code' => $row['transaction_code'],
        'paid_at' => $row['paid_at'],
        'order_date' => $row['order_date'],
        'order_total' => (float)$row['total_amount'],
        'products' => $products
    ];
}

// Get total count
$countSql = "SELECT COUNT(*) as total FROM payments p JOIN orders o ON p.order_id = o.id WHERE o.user_id = ?";
$countStmt = $conn->prepare($countSql);
$countStmt->bind_param("i", $userId);
$countStmt->execute();
$countResult = $countStmt->get_result();
$totalCount = $countResult->fetch_assoc()['total'];

$stmt->close();
$countStmt->close();
$conn->close();

sendResponse(true, 'Payments retrieved successfully', [
    'payments' => $payments,
    'pagination' => [
        'current_page' => $page,
        'per_page' => $limit,
        'total' => (int)$totalCount,
        'total_pages' => ceil($totalCount / $limit)
    ]
]);
?>
