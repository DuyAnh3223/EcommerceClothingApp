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
$cart_items = isset($input['cart_items']) ? $input['cart_items'] : [];

if (!$user_id || !$address_id || empty($cart_items)) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Thiếu thông tin đầu vào."
    ]);
    exit();
}

// Bắt đầu transaction
$conn->begin_transaction();

try {
    // Tính tổng tiền và platform fees
    $total_amount = 0;
    $total_platform_fee = 0;
    $order_items = []; // Lưu thông tin để thêm vào order_items
    
    foreach ($cart_items as $cart_item) {
        if ($cart_item['type'] === 'combination') {
            // Xử lý combo
            $combination_id = (int)$cart_item['combination_id'];
            $combination_quantity = (int)$cart_item['quantity'];
            $combination_price = (float)$cart_item['combination_price'];
            
            // Lấy thông tin chi tiết các sản phẩm trong combo
            $combo_sql = "SELECT pci.product_id, pci.variant_id, pci.quantity as item_quantity, pci.price_in_combination,
                                p.is_agency_product, p.platform_fee_rate, pv.price, pv.stock
                         FROM product_combination_items pci
                         JOIN products p ON pci.product_id = p.id
                         LEFT JOIN product_variant pv ON pci.product_id = pv.product_id AND pci.variant_id = pv.variant_id
                         WHERE pci.combination_id = ?";
            $combo_stmt = $conn->prepare($combo_sql);
            $combo_stmt->bind_param("i", $combination_id);
            $combo_stmt->execute();
            $combo_result = $combo_stmt->get_result();
            
            while ($combo_item = $combo_result->fetch_assoc()) {
                $product_id = (int)$combo_item['product_id'];
                $variant_id = (int)$combo_item['variant_id'];
                $item_quantity = (int)$combo_item['item_quantity'];
                $total_quantity = $item_quantity * $combination_quantity; // Số lượng trong combo * số lượng combo
                
                $base_price = (float)$combo_item['price'];
                $stock = (int)$combo_item['stock'];
                $is_agency_product = (bool)$combo_item['is_agency_product'];
                $platform_fee_rate = (float)$combo_item['platform_fee_rate'];
                
                // Kiểm tra tồn kho
                if ($stock < $total_quantity) {
                    throw new Exception("Sản phẩm trong combo đã hết hàng hoặc không đủ số lượng.");
                }
                
                $item_total = $base_price * $total_quantity;
                $item_platform_fee = 0;
                
                if ($is_agency_product) {
                    $item_platform_fee = $item_total * ($platform_fee_rate / 100);
                }
                
                $total_amount += $item_total + $item_platform_fee;
                $total_platform_fee += $item_platform_fee;
                
                // Lưu thông tin để thêm vào order_items
                $order_items[] = [
                    'product_id' => $product_id,
                    'variant_id' => $variant_id,
                    'quantity' => $total_quantity,
                    'price' => $base_price,
                    'platform_fee' => $item_platform_fee,
                    'is_agency_product' => $is_agency_product
                ];
            }
            $combo_stmt->close();
            
        } else {
            // Xử lý sản phẩm đơn lẻ
            $product_id = (int)$cart_item['product_id'];
            $variant_id = (int)$cart_item['variant_id'];
            $quantity = (int)$cart_item['quantity'];
            
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
                throw new Exception("Không tìm thấy sản phẩm hoặc biến thể.");
            }
            
            $product_info = $result->fetch_assoc();
            $base_price = (float)$product_info['price'];
            $stock = (int)$product_info['stock'];
            $is_agency_product = (bool)$product_info['is_agency_product'];
            $platform_fee_rate = (float)$product_info['platform_fee_rate'];
            
            if ($stock < $quantity) {
                throw new Exception("Sản phẩm đã hết hàng hoặc không đủ số lượng.");
            }
            
            $item_total = $base_price * $quantity;
            $item_platform_fee = 0;
            
            if ($is_agency_product) {
                $item_platform_fee = $item_total * ($platform_fee_rate / 100);
            }
            
            $total_amount += $item_total + $item_platform_fee;
            $total_platform_fee += $item_platform_fee;
            
            // Lưu thông tin để thêm vào order_items
            $order_items[] = [
                'product_id' => $product_id,
                'variant_id' => $variant_id,
                'quantity' => $quantity,
                'price' => $base_price,
                'platform_fee' => $item_platform_fee,
                'is_agency_product' => $is_agency_product
            ];
            
            $stmt->close();
        }
    }
    
    // Tạo đơn hàng
    $order_sql = "INSERT INTO orders (user_id, address_id, total_amount, platform_fee, status) VALUES (?, ?, ?, ?, 'pending')";
    $order_stmt = $conn->prepare($order_sql);
    $order_stmt->bind_param("iidd", $user_id, $address_id, $total_amount, $total_platform_fee);
    $order_stmt->execute();
    $order_id = $order_stmt->insert_id;
    $order_stmt->close();
    
    // Thêm từng sản phẩm vào order_items và trừ tồn kho
    foreach ($order_items as $item) {
        $product_id = $item['product_id'];
        $variant_id = $item['variant_id'];
        $quantity = $item['quantity'];
        $base_price = $item['price'];
        $platform_fee = $item['platform_fee'];
        
        $final_price = $base_price + ($platform_fee / $quantity); // Giá cuối cho 1 sản phẩm
        
        $item_sql = "INSERT INTO order_items (order_id, product_id, variant_id, quantity, price, platform_fee) VALUES (?, ?, ?, ?, ?, ?)";
        $item_stmt = $conn->prepare($item_sql);
        $item_stmt->bind_param("iiiddd", $order_id, $product_id, $variant_id, $quantity, $final_price, $platform_fee);
        $item_stmt->execute();
        $item_stmt->close();
        
        // Trừ tồn kho
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
    
    // Commit transaction
    $conn->commit();
    
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
        
        // Tạo URL thanh toán VNPAY
        $vnpay_result = createVNPayPaymentUrlFixed($order_id, $total_amount, $user_data);
        
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
    } 
    // Nếu là thanh toán BACoin, thực hiện trừ coin
    else if ($payment_method === 'BACoin') {
        try {
            // Bắt đầu transaction mới cho việc thanh toán BACoin
            $conn->begin_transaction();
            
            // Kiểm tra số dư BACoin
            $balance_sql = "SELECT balance FROM users WHERE id = ? FOR UPDATE";
            $balance_stmt = $conn->prepare($balance_sql);
            $balance_stmt->bind_param("i", $user_id);
            $balance_stmt->execute();
            $balance_result = $balance_stmt->get_result();
            $user_balance = $balance_result->fetch_assoc();
            $balance_stmt->close();
            
            if (!$user_balance) {
                throw new Exception('Không tìm thấy user');
            }
            
            $current_balance = $user_balance['balance'] ?? 0;
            
            if ($current_balance < $total_amount) {
                throw new Exception('Số dư BACoin không đủ. Hiện tại: ' . $current_balance . ', Cần: ' . $total_amount);
            }
            
            // Trừ BACoin
            $new_balance = $current_balance - $total_amount;
            $update_balance_sql = "UPDATE users SET balance = ? WHERE id = ?";
            $update_balance_stmt = $conn->prepare($update_balance_sql);
            $update_balance_stmt->bind_param("di", $new_balance, $user_id);
            $update_balance_stmt->execute();
            $update_balance_stmt->close();
            
            // Ghi nhận giao dịch BACoin
            $transaction_sql = "INSERT INTO bacoin_transactions (user_id, amount, type, description) VALUES (?, ?, 'spend', ?)";
            $transaction_stmt = $conn->prepare($transaction_sql);
            $desc = "Thanh toán đơn hàng #$order_id";
            $transaction_stmt->bind_param("ids", $user_id, $total_amount, $desc);
            $transaction_stmt->execute();
            $transaction_stmt->close();
            
            // Tạo mã giao dịch cho BACoin
            function generateTransactionCode($paymentMethod) {
                $prefix = '';
                switch ($paymentMethod) {
                    case 'Momo':
                        $prefix = 'MOMO';
                        break;
                    case 'VNPAY':
                        $prefix = 'VNPAY';
                        break;
                    case 'Bank':
                        $prefix = 'BANK';
                        break;
                    case 'COD':
                        $prefix = 'COD';
                        break;
                    case 'BACoin':
                        $prefix = 'BACOIN';
                        break;
                    default:
                        $prefix = 'TXN';
                }
                
                // Tạo 8 số ngẫu nhiên
                $randomNumbers = str_pad(mt_rand(1, 99999999), 8, '0', STR_PAD_LEFT);
                
                // Thêm timestamp để đảm bảo unique
                $timestamp = date('YmdHis');
                
                return $prefix . $timestamp . $randomNumbers;
            }
            
            $transaction_code = generateTransactionCode('BACoin');
            
            // Cập nhật trạng thái thanh toán và mã giao dịch
            $update_payment_sql = "UPDATE payments SET status = 'paid', paid_at = NOW(), payment_method = 'BACoin', amount_bacoin = ?, transaction_code = ? WHERE order_id = ?";
            $update_payment_stmt = $conn->prepare($update_payment_sql);
            $update_payment_stmt->bind_param("dsi", $total_amount, $transaction_code, $order_id);
            $update_payment_stmt->execute();
            $update_payment_stmt->close();
            
            // Cập nhật trạng thái đơn hàng thành confirmed
            $update_order_sql = "UPDATE orders SET status = 'confirmed', updated_at = NOW() WHERE id = ?";
            $update_order_stmt = $conn->prepare($update_order_sql);
            $update_order_stmt->bind_param("i", $order_id);
            $update_order_stmt->execute();
            $update_order_stmt->close();
            
            // Commit transaction
            $conn->commit();
            
            http_response_code(200);
            echo json_encode([
                "success" => true,
                "message" => "Đặt hàng thành công! Đã trừ " . $total_amount . " BACoin từ tài khoản. Đơn hàng đã được xác nhận.",
                "order_id" => $order_id,
                "payment_method" => "BACoin",
                "requires_payment" => false,
                "order_status" => "confirmed",
                "new_balance" => $new_balance,
                "amount_deducted" => $total_amount,
                "transaction_code" => $transaction_code
            ]);
            
        } catch (Exception $e) {
            // Rollback nếu có lỗi
            $conn->rollback();
            
            http_response_code(400);
            echo json_encode([
                "success" => false,
                "message" => "Lỗi thanh toán BACoin: " . $e->getMessage(),
                "order_id" => $order_id,
                "payment_method" => "BACoin"
            ]);
        }
    } else {
        http_response_code(200);
        echo json_encode([
            "success" => true,
            "message" => "Đặt hàng thành công!",
            "order_id" => $order_id,
            "payment_method" => $payment_method,
            "requires_payment" => false
        ]);
    }
    
} catch (Exception $e) {
    // Rollback transaction nếu có lỗi
    $conn->rollback();
    
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => $e->getMessage()
    ]);
}

$conn->close();

// Function tạo URL thanh toán VNPAY (simplified version)
function createVNPayPaymentUrlFixed($orderId, $amount, $userData) {
    try {
        // Include VNPAY config
        require_once '../vnpay_php/config.php';
        
        // Sử dụng thời gian hiện tại chính xác
        $currentTime = new DateTime('now', new DateTimeZone('Asia/Ho_Chi_Minh'));
        $vnp_CreateDate = $currentTime->format('YmdHis');
        
        // Thời gian hết hạn: 15 phút từ hiện tại
        $expireTime = $currentTime->add(new DateInterval('PT15M'));
        $vnp_ExpireDate = $expireTime->format('YmdHis');
        
        $vnp_TxnRef = $orderId;
        $vnp_OrderInfo = "Thanh toan don hang #$orderId";
        $vnp_OrderType = "other";
        $vnp_Amount = $amount * 100; // VNPAY yêu cầu số tiền nhân với 100
        $vnp_Locale = "vn";
        $vnp_IpAddr = $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1';
        $vnp_TmnCode = VNPAY_TMN_CODE;
        $vnp_HashSecret = VNPAY_HASH_SECRET_KEY;
        $vnp_Url = VNPAY_PAYMENT_URL;
        $vnp_Returnurl = VNPAY_RETURN_URL;
        
        $inputData = array(
            "vnp_Version" => "2.1.0",
            "vnp_TmnCode" => $vnp_TmnCode,
            "vnp_Amount" => $vnp_Amount,
            "vnp_Command" => "pay",
            "vnp_CreateDate" => $vnp_CreateDate,
            "vnp_CurrCode" => "VND",
            "vnp_IpAddr" => $vnp_IpAddr,
            "vnp_Locale" => $vnp_Locale,
            "vnp_OrderInfo" => $vnp_OrderInfo,
            "vnp_OrderType" => $vnp_OrderType,
            "vnp_ReturnUrl" => $vnp_Returnurl,
            "vnp_TxnRef" => $vnp_TxnRef,
            "vnp_ExpireDate" => $vnp_ExpireDate,
        );
        
        ksort($inputData);
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
        
        $vnp_Url = $vnp_Url . "?" . $query;
        if (isset($vnp_HashSecret)) {
            $vnpSecureHash = hash_hmac('sha512', $hashdata, $vnp_HashSecret);
            $vnp_Url .= 'vnp_SecureHash=' . $vnpSecureHash;
        }
        
        return [
            'success' => true,
            'payment_url' => $vnp_Url
        ];
        
    } catch (Exception $e) {
        return [
            'success' => false,
            'message' => $e->getMessage()
        ];
    }
}
?> 