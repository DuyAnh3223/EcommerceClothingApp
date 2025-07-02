<?php
// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../config/db_connect.php';

$input = json_decode(file_get_contents('php://input'), true);
$user_id = isset($input['user_id']) ? (int)$input['user_id'] : 0;
$address_id = isset($input['address_id']) ? (int)$input['address_id'] : 0;
$payment_method = isset($input['payment_method']) ? $input['payment_method'] : 'COD';
$items = isset($input['items']) ? $input['items'] : [];

if (!$user_id || !$address_id || empty($items)) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Thiếu thông tin đầu vào."
    ]);
    exit();
}

// Tính tổng tiền và platform fees
$total_amount = 0;
$total_platform_fee = 0;
foreach ($items as $item) {
    $product_id = (int)$item['product_id'];
    $variant_id = (int)$item['variant_id'];
    $quantity = (int)$item['quantity'];
    
    // Get product and variant info with platform fee calculation
    $stmt = $conn->prepare("
        SELECT p.is_agency_product, p.platform_fee_rate, pv.price, pv.stock 
        FROM products p 
        JOIN product_variant pv ON p.id = pv.product_id 
        WHERE p.id = ? AND pv.variant_id = ? AND p.status = 'active' AND pv.status = 'active'
    ");
    $stmt->bind_param("ii", $product_id, $variant_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        echo json_encode(["success" => false, "message" => "Không tìm thấy sản phẩm hoặc biến thể."]);
        exit();
    }
    
    $product_info = $result->fetch_assoc();
    $base_price = (float)$product_info['price'];
    $stock = (int)$product_info['stock'];
    $is_agency_product = (bool)$product_info['is_agency_product'];
    $platform_fee_rate = (float)$product_info['platform_fee_rate'];
    
    if ($stock < $quantity) {
        echo json_encode(["success" => false, "message" => "Sản phẩm đã hết hàng hoặc không đủ số lượng."]);
        exit();
    }
    
    $item_total = $base_price * $quantity;
    $item_platform_fee = 0;
    
    if ($is_agency_product) {
        $item_platform_fee = $item_total * ($platform_fee_rate / 100);
    }
    
    $total_amount += $item_total + $item_platform_fee;
    $total_platform_fee += $item_platform_fee;
    $stmt->close();
}

// Tạo đơn hàng
$order_sql = "INSERT INTO orders (user_id, address_id, total_amount, platform_fee, status) VALUES (?, ?, ?, ?, 'pending')";
$order_stmt = $conn->prepare($order_sql);
$order_stmt->bind_param("iidd", $user_id, $address_id, $total_amount, $total_platform_fee);
$order_stmt->execute();
$order_id = $order_stmt->insert_id;
$order_stmt->close();

// Thêm từng sản phẩm vào order_items và trừ tồn kho
foreach ($items as $item) {
    $product_id = (int)$item['product_id'];
    $variant_id = (int)$item['variant_id'];
    $quantity = (int)$item['quantity'];
    
    // Get product and variant info again for order items
    $stmt = $conn->prepare("
        SELECT p.is_agency_product, p.platform_fee_rate, pv.price 
        FROM products p 
        JOIN product_variant pv ON p.id = pv.product_id 
        WHERE p.id = ? AND pv.variant_id = ? AND p.status = 'active' AND pv.status = 'active'
    ");
    $stmt->bind_param("ii", $product_id, $variant_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $product_info = $result->fetch_assoc();
    
    $base_price = (float)$product_info['price'];
    $is_agency_product = (bool)$product_info['is_agency_product'];
    $platform_fee_rate = (float)$product_info['platform_fee_rate'];
    
    $final_price = $base_price;
    $item_platform_fee = 0;
    
    if ($is_agency_product) {
        $item_platform_fee = $base_price * ($platform_fee_rate / 100);
        $final_price = $base_price + $item_platform_fee;
    }
    
    // Tính platform fee cho toàn bộ quantity
    $total_item_platform_fee = $item_platform_fee * $quantity;
    
    $item_sql = "INSERT INTO order_items (order_id, product_id, variant_id, quantity, price, platform_fee) VALUES (?, ?, ?, ?, ?, ?)";
    $item_stmt = $conn->prepare($item_sql);
    $item_stmt->bind_param("iiiddd", $order_id, $product_id, $variant_id, $quantity, $final_price, $total_item_platform_fee);
    $item_stmt->execute();
    $item_stmt->close();

    $update_stock_sql = "UPDATE product_variant SET stock = stock - ? WHERE product_id = ? AND variant_id = ?";
    $update_stock_stmt = $conn->prepare($update_stock_sql);
    $update_stock_stmt->bind_param("iii", $quantity, $product_id, $variant_id);
    $update_stock_stmt->execute();
    $update_stock_stmt->close();
}

// Thêm payment
$pay_sql = "INSERT INTO payments (order_id, payment_method, amount, status) VALUES (?, ?, ?, 'pending')";
$pay_stmt = $conn->prepare($pay_sql);
$pay_stmt->bind_param("isd", $order_id, $payment_method, $total_amount);
$pay_stmt->execute();
$pay_stmt->close();

// Nếu là thanh toán VNPAY, tạo URL thanh toán
if ($payment_method === 'VNPAY') {
    // Lấy thông tin user
    $user_sql = "SELECT username, email, phone FROM users WHERE id = ?";
    $user_stmt = $conn->prepare($user_sql);
    $user_stmt->bind_param("i", $user_id);
    $user_stmt->execute();
    $user_result = $user_stmt->get_result();
    $user_data = $user_result->fetch_assoc();
    $user_stmt->close();

    // Tạo URL thanh toán VNPAY sử dụng function đã fix
    $vnpay_result = createVNPayPaymentUrlFixed($order_id, $total_amount, $user_data);
    
    $conn->close();
    
    if ($vnpay_result['success']) {
        http_response_code(200);
        echo json_encode([
            "success" => true,
            "message" => "Đặt hàng thành công! Vui lòng thanh toán qua VNPAY.",
            "order_id" => $order_id,
            "payment_method" => "VNPAY",
            "payment_url" => $vnpay_result['payment_url'],
            "requires_payment" => true
        ]);
    } else {
        http_response_code(500);
        echo json_encode([
            "success" => false,
            "message" => "Đặt hàng thành công nhưng có lỗi khi tạo URL thanh toán VNPAY: " . $vnpay_result['message'],
            "order_id" => $order_id,
            "payment_method" => "VNPAY",
            "requires_payment" => false
        ]);
    }
} else {
    $conn->close();
    
    http_response_code(200);
    echo json_encode([
        "success" => true,
        "message" => "Đặt hàng thành công!",
        "order_id" => $order_id,
        "payment_method" => $payment_method,
        "requires_payment" => false
    ]);
}

// Function tạo URL thanh toán VNPAY sử dụng API đã fix (simplified version)
function createVNPayPaymentUrlFixed($orderId, $amount, $userData) {
    try {
        // Include VNPAY config
        require_once '../vnpay_php/config.php';
        
        // Sử dụng thời gian hiện tại chính xác
        $currentTime = new DateTime('now', new DateTimeZone('Asia/Ho_Chi_Minh'));
        $vnp_CreateDate = $currentTime->format('YmdHis');
        
        // Thời gian hết hạn: 15 phút từ hiện tại
        $expireTime = clone $currentTime;
        $expireTime->add(new DateInterval('PT15M'));
        $vnp_ExpireDate = $expireTime->format('YmdHis');

        // Tạo input data cho VNPAY
        $inputData = array(
            "vnp_Version" => "2.1.0",
            "vnp_TmnCode" => $vnp_TmnCode,
            "vnp_Amount" => $amount * 100, // VNPAY yêu cầu nhân 100
            "vnp_Command" => "pay",
            "vnp_CreateDate" => $vnp_CreateDate,
            "vnp_CurrCode" => "VND",
            "vnp_IpAddr" => $_SERVER['REMOTE_ADDR'],
            "vnp_Locale" => "vn",
            "vnp_OrderInfo" => "Thanh toán đơn hàng #$orderId",
            "vnp_OrderType" => "other",
            "vnp_ReturnUrl" => $vnp_Returnurl,
            "vnp_TxnRef" => $orderId,
            "vnp_ExpireDate" => $vnp_ExpireDate
        );

        // Thêm thông tin khách hàng nếu có
        if (!empty($userData['phone'])) {
            $inputData['vnp_Bill_Mobile'] = $userData['phone'];
        }
        if (!empty($userData['email'])) {
            $inputData['vnp_Bill_Email'] = $userData['email'];
        }
        if (!empty($userData['username'])) {
            $inputData['vnp_Bill_FirstName'] = $userData['username'];
        }

        // Sắp xếp theo key
        ksort($inputData);

        // Tạo query string và hash data
        $query = "";
        $hashdata = "";
        $i = 0;
        foreach ($inputData as $key => $value) {
            if ($i == 1) {
                $hashdata .= '&' . urlencode($key) . "=" . urlencode($value);
            } else {
                $hashdata .= urlencode($key) . "=" . urlencode($value);
                $i = 1;
            }
            $query .= urlencode($key) . "=" . urlencode($value) . '&';
        }

        // Tạo secure hash
        $vnpSecureHash = hash_hmac('sha512', $hashdata, $vnp_HashSecret);
        
        // Tạo URL thanh toán cuối cùng
        $vnp_Url = $vnp_Url . "?" . $query . "vnp_SecureHash=" . $vnpSecureHash;

        return [
            'success' => true,
            'payment_url' => $vnp_Url,
            'message' => 'Payment URL created successfully'
        ];
    } catch (Exception $e) {
        return [
            'success' => false,
            'message' => 'Exception: ' . $e->getMessage()
        ];
    }
}

// Function tạo URL thanh toán VNPAY cũ (backup)
function createVNPayPaymentUrl($orderId, $amount, $userData) {
    require_once '../vnpay_php/config.php';
    
    $vnp_TxnRef = $orderId;
    $vnp_OrderInfo = "Thanh toán đơn hàng #$orderId";
    $vnp_Amount = $amount * 100; // VNPAY yêu cầu nhân 100
    $vnp_Locale = 'vn';
    $vnp_IpAddr = $_SERVER['REMOTE_ADDR'];
    $vnp_ExpireDate = date('YmdHis', strtotime('+15 minutes'));

    // Thông tin khách hàng
    $vnp_Bill_Mobile = $userData['phone'] ?? '';
    $vnp_Bill_Email = $userData['email'] ?? '';
    $vnp_Bill_FirstName = $userData['username'] ?? '';

    // Tách tên thành first name và last name
    $vnp_Bill_LastName = '';
    if (!empty($vnp_Bill_FirstName)) {
        $name = explode(' ', trim($vnp_Bill_FirstName));
        if (count($name) > 1) {
            $vnp_Bill_FirstName = array_shift($name);
            $vnp_Bill_LastName = implode(' ', $name);
        }
    }

    // Tạo input data cho VNPAY
    $inputData = array(
        "vnp_Version" => "2.1.0",
        "vnp_TmnCode" => $vnp_TmnCode,
        "vnp_Amount" => $vnp_Amount,
        "vnp_Command" => "pay",
        "vnp_CreateDate" => date('YmdHis'),
        "vnp_CurrCode" => "VND",
        "vnp_IpAddr" => $vnp_IpAddr,
        "vnp_Locale" => $vnp_Locale,
        "vnp_OrderInfo" => $vnp_OrderInfo,
        "vnp_OrderType" => "other",
        "vnp_ReturnUrl" => $vnp_Returnurl,
        "vnp_TxnRef" => $vnp_TxnRef,
        "vnp_ExpireDate" => $vnp_ExpireDate
    );

    // Thêm thông tin khách hàng nếu có
    if (!empty($vnp_Bill_Mobile)) {
        $inputData['vnp_Bill_Mobile'] = $vnp_Bill_Mobile;
    }
    if (!empty($vnp_Bill_Email)) {
        $inputData['vnp_Bill_Email'] = $vnp_Bill_Email;
    }
    if (!empty($vnp_Bill_FirstName)) {
        $inputData['vnp_Bill_FirstName'] = $vnp_Bill_FirstName;
    }
    if (!empty($vnp_Bill_LastName)) {
        $inputData['vnp_Bill_LastName'] = $vnp_Bill_LastName;
    }

    // Sắp xếp theo key
    ksort($inputData);

    // Tạo query string
    $query = "";
    $i = 0;
    $hashdata = "";
    foreach ($inputData as $key => $value) {
        if ($i == 1) {
            $hashdata .= '&' . urlencode($key) . "=" . urlencode($value);
        } else {
            $hashdata .= urlencode($key) . "=" . urlencode($value);
            $i = 1;
        }
        $query .= urlencode($key) . "=" . urlencode($value) . '&';
    }

    // Tạo URL thanh toán
    $vnp_Url = $vnp_Url . "?" . $query;

    // Tạo secure hash
    if (isset($vnp_HashSecret)) {
        $vnpSecureHash = hash_hmac('sha512', $hashdata, $vnp_HashSecret);
        $vnp_Url .= 'vnp_SecureHash=' . $vnpSecureHash;
    }

    return $vnp_Url;
}
?> 