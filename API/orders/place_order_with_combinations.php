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
require_once '../config/config.php';

// Lấy dữ liệu từ request (hỗ trợ cả POST form và JSON)
$input = [];

// Thử lấy từ POST form data
if (!empty($_POST)) {
    $input = $_POST;
    error_log("DEBUG ORDER: Using POST form data: " . json_encode($input));
}
// Thử lấy từ JSON
else {
    $raw_input = file_get_contents('php://input');
    error_log("DEBUG ORDER: Raw input: " . $raw_input);
    
    if (!empty($raw_input)) {
        $input = json_decode($raw_input, true);
        $json_error = json_last_error();
        if ($json_error !== JSON_ERROR_NONE) {
            error_log("DEBUG ORDER: JSON decode error: " . json_last_error_msg());
            http_response_code(400);
            echo json_encode([
                "success" => false,
                "message" => "Lỗi parse JSON: " . json_last_error_msg() . ". Raw input: " . substr($raw_input, 0, 200)
            ]);
            exit();
        }
        error_log("DEBUG ORDER: Using JSON data: " . json_encode($input));
    } else {
        error_log("DEBUG ORDER: No input data received");
    }
}

// Debug log
error_log("DEBUG ORDER: Final input data: " . json_encode($input));

$user_id = isset($input['user_id']) ? (int)$input['user_id'] : 0;
$address_id = isset($input['address_id']) ? (int)$input['address_id'] : 0;
$payment_method = isset($input['payment_method']) ? $input['payment_method'] : 'COD';
$cart_items = isset($input['cart_items']) ? $input['cart_items'] : [];

// Voucher parameters
$voucher_id = isset($input['voucher_id']) ? (int)$input['voucher_id'] : null;
$voucher_code = isset($input['voucher_code']) ? $input['voucher_code'] : null;
$discount_amount = isset($input['discount_amount']) ? (float)$input['discount_amount'] : 0.0;

error_log("DEBUG ORDER: Parsed data - user_id=$user_id, address_id=$address_id, payment_method=$payment_method, cart_items_count=" . count($cart_items));
error_log("DEBUG ORDER: Voucher info - voucher_id=$voucher_id, voucher_code=$voucher_code, discount_amount=$discount_amount");

// Kiểm tra chi tiết từng field
$missing_fields = [];
if (!$user_id) $missing_fields[] = 'user_id';
if (!$address_id) $missing_fields[] = 'address_id';
if (empty($cart_items)) $missing_fields[] = 'cart_items';

if (!empty($missing_fields)) {
    http_response_code(400);
    $error_msg = "Thiếu thông tin đầu vào: " . implode(', ', $missing_fields) . ". user_id=$user_id, address_id=$address_id, cart_items_count=" . count($cart_items);
    error_log("DEBUG ORDER ERROR: " . $error_msg);
    echo json_encode([
        "success" => false,
        "message" => $error_msg,
        "debug_info" => [
            "received_fields" => array_keys($input),
            "missing_fields" => $missing_fields,
            "raw_input" => substr($raw_input ?? '', 0, 200)
        ]
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
    
    // Áp dụng voucher discount nếu có
    $original_total = $total_amount;
    $final_total = $total_amount;
    $voucher_applied = false;
    $voucher_discount = 0;
    
    if ($voucher_id && $discount_amount > 0) {
        // Validate voucher
        $voucher_sql = "SELECT id, voucher_code, discount_amount, quantity, 
                               (SELECT COUNT(*) FROM voucher_usage WHERE voucher_id = vouchers.id) as used_count
                        FROM vouchers WHERE id = ?";
        $voucher_stmt = $conn->prepare($voucher_sql);
        $voucher_stmt->bind_param("i", $voucher_id);
        $voucher_stmt->execute();
        $voucher_result = $voucher_stmt->get_result();
        
        if ($voucher_result->num_rows > 0) {
            $voucher_data = $voucher_result->fetch_assoc();
            $remaining_quantity = $voucher_data['quantity'] - $voucher_data['used_count'];
            
            if ($remaining_quantity > 0) {
                // Áp dụng discount
                $final_total = $total_amount - $discount_amount;
                if ($final_total < 0) $final_total = 0; // Không âm
                
                $voucher_applied = true;
                $voucher_discount = $discount_amount;
                
                error_log("DEBUG ORDER: Voucher applied - voucher_id=$voucher_id, original_total=$original_total, discount_amount=$discount_amount, final_total=$final_total");
            } else {
                error_log("DEBUG ORDER: Voucher has no remaining quantity");
            }
        } else {
            error_log("DEBUG ORDER: Voucher not found - voucher_id=$voucher_id");
        }
        $voucher_stmt->close();
    }
    
    // Tạo đơn hàng với total_amount đã được áp dụng voucher
    // Nếu thanh toán bằng BACoin, không lưu platform_fee vào database
    // Platform fee sẽ được tính trực tiếp vào total_amount_bacoin
    $platform_fee_to_save = ($payment_method === 'BACoin') ? 0 : $total_platform_fee;
    
    $order_sql = "INSERT INTO orders (user_id, address_id, total_amount, platform_fee, status) VALUES (?, ?, ?, ?, 'pending')";
    $order_stmt = $conn->prepare($order_sql);
    $order_stmt->bind_param("iidd", $user_id, $address_id, $final_total, $platform_fee_to_save);
    $order_stmt->execute();
    $order_id = $order_stmt->insert_id;
    $order_stmt->close();
    
    // Ghi nhận sử dụng voucher sau khi order được tạo
    if ($voucher_applied && $voucher_id) {
        $usage_sql = "INSERT INTO voucher_usage (voucher_id, user_id, order_id, discount_applied) VALUES (?, ?, ?, ?)";
        $usage_stmt = $conn->prepare($usage_sql);
        $usage_stmt->bind_param("iiid", $voucher_id, $user_id, $order_id, $voucher_discount);
        $usage_stmt->execute();
        $usage_stmt->close();
        error_log("DEBUG ORDER: Voucher usage recorded - voucher_id=$voucher_id, order_id=$order_id, discount=$voucher_discount");
    }
    
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
    $pay_stmt->bind_param("isd", $order_id, $payment_method, $final_total);
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
        $vnpay_result = createVNPayPaymentUrlFixed($order_id, $final_total, $user_data);
        
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
        error_log("DEBUG ORDER: Processing BACoin payment for order_id=$order_id, total_amount=$final_total");
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
            error_log("DEBUG ORDER: User balance check - user_id=$user_id, current_balance=$current_balance, required=$final_total");
            
            if ($current_balance < $final_total) {
                throw new Exception('Số dư BACoin không đủ. Hiện tại: ' . $current_balance . ', Cần: ' . $final_total);
            }
            
            // 1. Trừ BACoin từ user mua hàng
            $new_balance = $current_balance - $final_total;
            $update_balance_sql = "UPDATE users SET balance = ? WHERE id = ?";
            $update_balance_stmt = $conn->prepare($update_balance_sql);
            $update_balance_stmt->bind_param("di", $new_balance, $user_id);
            $update_balance_stmt->execute();
            $update_balance_stmt->close();
            
            // 2. Ghi nhận giao dịch trừ BACoin của user
            $transaction_sql = "INSERT INTO bacoin_transactions (user_id, amount, type, description) VALUES (?, ?, 'spend', ?)";
            $transaction_stmt = $conn->prepare($transaction_sql);
            $desc = "Thanh toán đơn hàng #$order_id";
            $transaction_stmt->bind_param("ids", $user_id, $final_total, $desc);
            $transaction_stmt->execute();
            $transaction_stmt->close();
            
                        // 3. Phân bổ BACoin cho admin/agency
            $admin_balance = 0;
            $agency_balance = 0;
            
            error_log("DEBUG ORDER: Starting BACoin distribution for order_id=$order_id");
            
            // Lấy thông tin chi tiết các sản phẩm trong đơn hàng để phân bổ
            $order_items_sql = "SELECT oi.product_id, oi.quantity, oi.price, p.is_agency_product, p.created_by as agency_id, p.platform_fee_rate
                               FROM order_items oi 
                               JOIN products p ON oi.product_id = p.id 
                               WHERE oi.order_id = ?";
            $order_items_stmt = $conn->prepare($order_items_sql);
            $order_items_stmt->bind_param("i", $order_id);
            $order_items_stmt->execute();
            $order_items_result = $order_items_stmt->get_result();
            
            while ($item = $order_items_result->fetch_assoc()) {
                $item_total = $item['price'] * $item['quantity'];
                
                error_log("DEBUG ORDER: Processing item - product_id={$item['product_id']}, quantity={$item['quantity']}, price={$item['price']}, total=$item_total, is_agency={$item['is_agency_product']}");
                
                if ($item['is_agency_product']) {
                    // Sản phẩm của agency: Agency nhận giá gốc, Admin nhận phí sàn
                    $platform_fee_rate = $item['platform_fee_rate'] ?? AGENCY_PLATFORM_FEE_RATE;
                    $agency_amount = $item_total / (1 + $platform_fee_rate / 100); // Giá gốc
                    $admin_amount = $item_total - $agency_amount; // Phí sàn
                    
                    error_log("DEBUG ORDER: Agency product - platform_fee_rate=$platform_fee_rate, agency_amount=$agency_amount, admin_amount=$admin_amount");
                    
                    $agency_balance += $agency_amount;
                    $admin_balance += $admin_amount;
                    
                    // Cộng BACoin cho agency
                    $agency_id = $item['agency_id'];
                    
                    // Kiểm tra xem agency_id có tồn tại trong bảng users không
                    $check_agency_sql = "SELECT id FROM users WHERE id = ? AND role = 'agency'";
                    $check_agency_stmt = $conn->prepare($check_agency_sql);
                    $check_agency_stmt->bind_param("i", $agency_id);
                    $check_agency_stmt->execute();
                    $check_agency_result = $check_agency_stmt->get_result();
                    
                    if ($check_agency_result->num_rows > 0) {
                        $agency_update_sql = "UPDATE users SET balance = IFNULL(balance, 0) + ? WHERE id = ?";
                        $agency_update_stmt = $conn->prepare($agency_update_sql);
                        $agency_update_stmt->bind_param("di", $agency_amount, $agency_id);
                        $agency_update_stmt->execute();
                        $agency_update_stmt->close();
                        
                        // Ghi nhận giao dịch cho agency
                        $agency_transaction_sql = "INSERT INTO bacoin_transactions (user_id, amount, type, description) VALUES (?, ?, 'receive', ?)";
                        $agency_transaction_stmt = $conn->prepare($agency_transaction_sql);
                        $agency_desc = "Nhận thanh toán đơn hàng #$order_id (giá gốc)";
                        $agency_transaction_stmt->bind_param("ids", $agency_id, $agency_amount, $agency_desc);
                        $agency_transaction_stmt->execute();
                        $agency_transaction_stmt->close();
                        
                        error_log("DEBUG ORDER: Added BACoin to agency - agency_id=$agency_id, amount=$agency_amount");
                    } else {
                        error_log("DEBUG ORDER: Agency not found - agency_id=$agency_id, skipping agency payment");
                    }
                    $check_agency_stmt->close();
                    
                } else {
                    // Sản phẩm của admin: 100% cho admin
                    $admin_balance += $item_total;
                }
            }
            $order_items_stmt->close();
            
            // 4. Cộng BACoin cho admin (nếu có)
            if ($admin_balance > 0) {
                // Lấy admin_id từ config
                $admin_id = ADMIN_USER_ID;
                
                error_log("DEBUG ORDER: Adding BACoin to admin - admin_id=$admin_id, amount=$admin_balance");
                
                // Kiểm tra xem admin_id có tồn tại trong bảng users không
                $check_admin_sql = "SELECT id FROM users WHERE id = ? AND role = 'admin'";
                $check_admin_stmt = $conn->prepare($check_admin_sql);
                $check_admin_stmt->bind_param("i", $admin_id);
                $check_admin_stmt->execute();
                $check_admin_result = $check_admin_stmt->get_result();
                
                if ($check_admin_result->num_rows > 0) {
                    $admin_update_sql = "UPDATE users SET balance = IFNULL(balance, 0) + ? WHERE id = ?";
                    $admin_update_stmt = $conn->prepare($admin_update_sql);
                    $admin_update_stmt->bind_param("di", $admin_balance, $admin_id);
                    $admin_update_stmt->execute();
                    $admin_update_stmt->close();
                    
                    // Ghi nhận giao dịch cho admin
                    $admin_transaction_sql = "INSERT INTO bacoin_transactions (user_id, amount, type, description) VALUES (?, ?, 'receive', ?)";
                    $admin_transaction_stmt = $conn->prepare($admin_transaction_sql);
                    $admin_desc = "Nhận thanh toán đơn hàng #$order_id";
                    $admin_transaction_stmt->bind_param("ids", $admin_id, $admin_balance, $admin_desc);
                    $admin_transaction_stmt->execute();
                    $admin_transaction_stmt->close();
                    
                    error_log("DEBUG ORDER: Added BACoin to admin - admin_id=$admin_id, amount=$admin_balance");
                } else {
                    error_log("DEBUG ORDER: Admin not found - admin_id=$admin_id, skipping admin payment");
                }
                $check_admin_stmt->close();
            }
            
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
            $update_payment_stmt->bind_param("dsi", $final_total, $transaction_code, $order_id);
            $update_payment_stmt->execute();
            $update_payment_stmt->close();
            
            // Khi thanh toán bằng BACoin: set total_amount = 0 và cập nhật total_amount_bacoin
            error_log("DEBUG ORDER: Updating order amounts for BACoin payment - order_id=$order_id, bacoin_amount=$final_total");
            $update_order_bacoin_sql = "UPDATE orders SET total_amount = 0, total_amount_bacoin = ? WHERE id = ?";
            $update_order_bacoin_stmt = $conn->prepare($update_order_bacoin_sql);
            $update_order_bacoin_stmt->bind_param("di", $final_total, $order_id);
            $update_order_bacoin_stmt->execute();
            $update_order_bacoin_stmt->close();
            
            // Cập nhật trạng thái đơn hàng thành confirmed
            $update_order_sql = "UPDATE orders SET status = 'confirmed', updated_at = NOW() WHERE id = ?";
            $update_order_stmt = $conn->prepare($update_order_sql);
            $update_order_stmt->bind_param("i", $order_id);
            $update_order_stmt->execute();
            $update_order_stmt->close();
            
            // Commit transaction
            $conn->commit();
            
            error_log("DEBUG ORDER: BACoin payment successful - order_id=$order_id, new_balance=$new_balance, admin_received=$admin_balance, agency_received=$agency_balance");
            http_response_code(200);
            echo json_encode([
                "success" => true,
                "message" => "Đặt hàng thành công! Đã trừ " . $final_total . " BACoin từ tài khoản. Đơn hàng đã được xác nhận.",
                "order_id" => $order_id,
                "payment_method" => "BACoin",
                "requires_payment" => false,
                "order_status" => "confirmed",
                "new_balance" => $new_balance,
                "amount_deducted" => $final_total,
                "transaction_code" => $transaction_code,
                "bacoin_distribution" => [
                    "admin_received" => $admin_balance,
                    "agency_received" => $agency_balance,
                    "total_distributed" => $admin_balance + $agency_balance
                ]
            ]);
            
        } catch (Exception $e) {
            // Rollback nếu có lỗi
            $conn->rollback();
            
            $error_msg = "Lỗi thanh toán BACoin: " . $e->getMessage();
            error_log("DEBUG ORDER ERROR: $error_msg");
            
            http_response_code(400);
            echo json_encode([
                "success" => false,
                "message" => $error_msg,
                "order_id" => $order_id,
                "payment_method" => "BACoin"
            ]);
        }
    } else {
        // Thanh toán bằng COD hoặc VNPAY - cập nhật total_amount
        $update_order_amount_sql = "UPDATE orders SET total_amount = ? WHERE id = ?";
        $update_order_amount_stmt = $conn->prepare($update_order_amount_sql);
        $update_order_amount_stmt->bind_param("di", $final_total, $order_id);
        $update_order_amount_stmt->execute();
        $update_order_amount_stmt->close();
        
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
    
    $error_msg = $e->getMessage();
    error_log("DEBUG ORDER ERROR: $error_msg");
    
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => $error_msg
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