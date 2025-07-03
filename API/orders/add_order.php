<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");
require_once '../config/db_connect.php';

$data = json_decode(file_get_contents("php://input"), true);

$user_id = $data['user_id'] ?? null;
$address_id = $data['address_id'] ?? null;
$items = $data['items'] ?? null; // Array of order items with product_id, variant_id, quantity
$status = $data['status'] ?? 'pending';

if (!$user_id || !$address_id || !$items || !is_array($items)) {
    echo json_encode(["success" => false, "message" => "Thiếu thông tin bắt buộc"]);
    exit();
}

try {
    $conn->begin_transaction();
    
    $total_amount = 0;
    $total_platform_fee = 0;
    
    // Calculate total amount and platform fees
    foreach ($items as $item) {
        $product_id = $item['product_id'];
        $variant_id = $item['variant_id'];
        $quantity = $item['quantity'];
        
        // Get product and variant info
        $stmt = $conn->prepare("
            SELECT p.is_agency_product, p.platform_fee_rate, pv.price 
            FROM products p 
            JOIN product_variant pv ON p.id = pv.product_id 
            WHERE p.id = ? AND pv.variant_id = ? AND p.status = 'active' AND pv.status = 'active'
        ");
        $stmt->bind_param("ii", $product_id, $variant_id);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows === 0) {
            throw new Exception("Product or variant not found or not available");
        }
        
        $product_info = $result->fetch_assoc();
        $base_price = $product_info['price'];
        $is_agency_product = $product_info['is_agency_product'];
        $platform_fee_rate = $product_info['platform_fee_rate'];
        
        $item_total = $base_price * $quantity;
        $item_platform_fee = 0;
        
        if ($is_agency_product) {
            $item_platform_fee = $item_total * ($platform_fee_rate / 100);
        }
        
        $total_amount += $item_total + $item_platform_fee;
        $total_platform_fee += $item_platform_fee;
    }
    
    // Insert order
    $stmt = $conn->prepare("INSERT INTO orders (user_id, address_id, total_amount, platform_fee, status) VALUES (?, ?, ?, ?, ?)");
    $stmt->bind_param("iidds", $user_id, $address_id, $total_amount, $total_platform_fee, $status);
    $stmt->execute();
    $order_id = $conn->insert_id;
    
    // Insert order items
    foreach ($items as $item) {
        $product_id = $item['product_id'];
        $variant_id = $item['variant_id'];
        $quantity = $item['quantity'];
        
        // Get product and variant info again for order items
        $stmt = $conn->prepare("
            SELECT p.is_agency_product, p.platform_fee_rate, pv.price, p.created_by, p.name 
            FROM products p 
            JOIN product_variant pv ON p.id = pv.product_id 
            WHERE p.id = ? AND pv.variant_id = ? AND p.status = 'active' AND pv.status = 'active'
        ");
        $stmt->bind_param("ii", $product_id, $variant_id);
        $stmt->execute();
        $result = $stmt->get_result();
        $product_info = $result->fetch_assoc();
        
        $base_price = $product_info['price'];
        $is_agency_product = $product_info['is_agency_product'];
        $platform_fee_rate = $product_info['platform_fee_rate'];
        $agency_id = $product_info['created_by'];
        $product_name = $product_info['name'];
        
        $final_price = $base_price;
        $item_platform_fee = 0;
        
        if ($is_agency_product) {
            $item_platform_fee = $base_price * ($platform_fee_rate / 100);
            $final_price = $base_price + $item_platform_fee;
        }
        
        $stmt = $conn->prepare("INSERT INTO order_items (order_id, product_id, variant_id, quantity, price, platform_fee) VALUES (?, ?, ?, ?, ?, ?)");
        $stmt->bind_param("iiiddd", $order_id, $product_id, $variant_id, $quantity, $final_price, $item_platform_fee);
        $stmt->execute();
        
        // Update stock
        $stmt = $conn->prepare("UPDATE product_variant SET stock = stock - ? WHERE product_id = ? AND variant_id = ?");
        $stmt->bind_param("iii", $quantity, $product_id, $variant_id);
        $stmt->execute();
        
        // Gửi thông báo cho agency nếu là sản phẩm của agency
        if ($is_agency_product && $agency_id) {
            $title = 'Sản phẩm của bạn đã được bán';
            $content = 'Sản phẩm: ' . $product_name . ' | Số lượng: ' . $quantity;
            $type = 'order_status';
            $stmtNotify = $conn->prepare("INSERT INTO notifications (user_id, title, content, type, is_read) VALUES (?, ?, ?, ?, 0)");
            $stmtNotify->bind_param("isss", $agency_id, $title, $content, $type);
            $stmtNotify->execute();
            $stmtNotify->close();
        }
    }
    
    $conn->commit();
    
    echo json_encode([
        "success" => true,
        "message" => "Tạo đơn hàng thành công",
        "order_id" => $order_id,
        "total_amount" => $total_amount,
        "platform_fee" => $total_platform_fee
    ]);
    
} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(["success" => false, "message" => "Lỗi: " . $e->getMessage()]);
}

$conn->close();
?>