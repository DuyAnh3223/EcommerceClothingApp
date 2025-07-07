<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

require_once '../config/db_connect.php';
require_once '../utils/response.php';

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

try {
    $user_id = $_GET['user_id'] ?? null;
    
    if (!$user_id) {
        sendResponse(false, 'User ID is required', null, 400);
        exit;
    }
    
    // Lấy thông tin giỏ hàng
    $sql = "SELECT 
                ci.id,
                ci.quantity,
                ci.combination_id,
                ci.combination_price,
                pv.price,
                pv.price_bacoin,
                p.name as product_name,
                p.main_image
            FROM cart_items ci
            LEFT JOIN product_variant pv ON ci.product_id = pv.product_id AND ci.variant_id = pv.variant_id
            LEFT JOIN products p ON ci.product_id = p.id
            WHERE ci.user_id = ?";
    
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $cart_items = [];
    while ($row = $result->fetch_assoc()) {
        $cart_items[] = $row;
    }
    $stmt->close();
    
    $total_amount = 0;
    $total_quantity = 0;
    $total_amount_bacoin = 0;
    $cart_summary = [];
    
    foreach ($cart_items as $item) {
        $quantity = (int)$item['quantity'];
        $price = (float)($item['combination_price'] ?? $item['price'] ?? 0);
        $price_bacoin = (float)($item['price_bacoin'] ?? 0);
        
        $total_amount += $price * $quantity;
        $total_quantity += $quantity;
        $total_amount_bacoin += $price_bacoin * $quantity;
        
        $cart_summary[] = [
            'id' => (int)$item['id'],
            'product_name' => $item['product_name'],
            'quantity' => $quantity,
            'price' => $price,
            'price_bacoin' => $price_bacoin,
            'subtotal' => $price * $quantity,
            'subtotal_bacoin' => $price_bacoin * $quantity,
            'image' => $item['main_image'],
            'is_combination' => !empty($item['combination_id'])
        ];
    }
    
    $response = [
        'cart_items' => $cart_summary,
        'summary' => [
            'total_amount' => $total_amount,
            'total_quantity' => $total_quantity,
            'total_amount_bacoin' => $total_amount_bacoin,
            'item_count' => count($cart_items)
        ]
    ];
    
    sendResponse(true, 'Lấy thông tin giỏ hàng thành công', $response);
    
} catch (Exception $e) {
    sendResponse(false, 'Server error: ' . $e->getMessage(), null, 500);
}
?> 