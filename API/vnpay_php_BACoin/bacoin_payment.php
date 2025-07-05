<?php
// Sử dụng kết nối database từ thư mục config chính
require_once("../config/db_connect.php");
require_once("../config/config.php");

header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Lấy dữ liệu từ request (hỗ trợ POST, GET và JSON)
$input = json_decode(file_get_contents('php://input'), true);

$user_id = 0;
$order_id = 0;

// Thử lấy từ POST
if (isset($_POST['user_id']) && isset($_POST['order_id'])) {
    $user_id = intval($_POST['user_id']);
    $order_id = intval($_POST['order_id']);
}
// Thử lấy từ GET
else if (isset($_GET['user_id']) && isset($_GET['order_id'])) {
    $user_id = intval($_GET['user_id']);
    $order_id = intval($_GET['order_id']);
}
// Thử lấy từ JSON
else if ($input && isset($input['user_id']) && isset($input['order_id'])) {
    $user_id = intval($input['user_id']);
    $order_id = intval($input['order_id']);
}

if ($user_id <= 0 || $order_id <= 0) {
    error_log("DEBUG BACOIN ERROR: user_id=$user_id, order_id=$order_id");
    error_log("DEBUG BACOIN ERROR: POST=" . json_encode($_POST));
    error_log("DEBUG BACOIN ERROR: GET=" . json_encode($_GET));
    error_log("DEBUG BACOIN ERROR: INPUT=" . json_encode($input));
    echo json_encode(['success' => false, 'message' => 'Thiếu tham số hoặc tham số không hợp lệ. user_id=' . $user_id . ', order_id=' . $order_id]);
    exit;
}

// Debug: Kiểm tra kết nối database
if (!$conn) {
    echo json_encode(['success' => false, 'message' => 'Lỗi kết nối database']);
    exit;
}

// Lấy total_amount từ bảng orders
$sql = "SELECT total_amount FROM orders WHERE id = ? AND user_id = ?";
$stmt = $conn->prepare($sql);
if (!$stmt) {
    echo json_encode(['success' => false, 'message' => 'Lỗi prepare query orders: ' . $conn->error]);
    exit;
}
$stmt->bind_param("ii", $order_id, $user_id);
$stmt->execute();
$stmt->bind_result($total_amount);
if (!$stmt->fetch()) {
    echo json_encode(['success' => false, 'message' => 'Không tìm thấy đơn hàng hoặc không đúng user']);
    exit;
}
$stmt->close();

if ($total_amount <= 0) {
    echo json_encode(['success' => false, 'message' => 'Đơn hàng không hợp lệ']);
    exit;
}

// Debug: Kiểm tra balance hiện tại
$sql = "SELECT balance FROM users WHERE id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $user_id);
$stmt->execute();
$stmt->bind_result($current_balance);
$stmt->fetch();
$stmt->close();

$current_balance = $current_balance ?? 0;

// Debug log
error_log("DEBUG BACOIN: User ID: $user_id, Order ID: $order_id, Total Amount: $total_amount, Current Balance: $current_balance");

$conn->begin_transaction();
try {
    // 1. Kiểm tra số dư BACoin với FOR UPDATE
    $sql = "SELECT balance FROM users WHERE id = ? FOR UPDATE";
    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        throw new Exception('Lỗi prepare query users: ' . $conn->error);
    }
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $stmt->bind_result($balance);
    if (!$stmt->fetch()) {
        throw new Exception('Không tìm thấy user');
    }
    $stmt->close();

    $balance = $balance ?? 0;

    if ($balance < $total_amount) {
        throw new Exception('Số dư BACoin không đủ. Hiện tại: ' . $balance . ', Cần: ' . $total_amount);
    }

    // 2. Trừ BACoin từ user mua hàng
    $new_balance = $balance - $total_amount;
    
    // Debug log
    error_log("DEBUG BACOIN: Old Balance: $balance, New Balance: $new_balance, Amount to deduct: $total_amount");
    
    $sql = "UPDATE users SET balance = ? WHERE id = ?";
    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        throw new Exception('Lỗi prepare update users: ' . $conn->error);
    }
    $stmt->bind_param("di", $new_balance, $user_id);
    $result = $stmt->execute();
    $affected_rows = $stmt->affected_rows;
    $stmt->close();
    
    if (!$result || $affected_rows === 0) {
        throw new Exception('Lỗi khi cập nhật số dư. Affected rows: ' . $affected_rows);
    }

    // 3. Ghi nhận giao dịch trừ BACoin của user
    $sql = "INSERT INTO bacoin_transactions (user_id, amount, type, description) VALUES (?, ?, 'spend', ?)";
    $desc = "Thanh toán đơn hàng #$order_id";
    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        throw new Exception('Lỗi prepare insert transactions: ' . $conn->error);
    }
    $stmt->bind_param("ids", $user_id, $total_amount, $desc);
    if (!$stmt->execute()) {
        throw new Exception('Lỗi khi ghi nhận giao dịch BACoin: ' . $stmt->error);
    }
    $stmt->close();

    // 4. Phân bổ BACoin cho admin/agency
    $admin_balance = 0;
    $agency_balance = 0;
    
    // Lấy thông tin chi tiết các sản phẩm trong đơn hàng để phân bổ
    $order_items_sql = "SELECT oi.product_id, oi.quantity, oi.price, p.is_agency_product, p.agency_id, p.platform_fee_rate
                       FROM order_items oi 
                       JOIN products p ON oi.product_id = p.id 
                       WHERE oi.order_id = ?";
    $order_items_stmt = $conn->prepare($order_items_sql);
    $order_items_stmt->bind_param("i", $order_id);
    $order_items_stmt->execute();
    $order_items_result = $order_items_stmt->get_result();
    
    while ($item = $order_items_result->fetch_assoc()) {
        $item_total = $item['price'] * $item['quantity'];
        
        if ($item['is_agency_product']) {
            // Sản phẩm của agency: Agency nhận giá gốc, Admin nhận phí sàn
            $platform_fee_rate = $item['platform_fee_rate'] ?? AGENCY_PLATFORM_FEE_RATE;
            $agency_amount = $item_total / (1 + $platform_fee_rate / 100); // Giá gốc
            $admin_amount = $item_total - $agency_amount; // Phí sàn
            
            $agency_balance += $agency_amount;
            $admin_balance += $admin_amount;
            
            // Cộng BACoin cho agency
            $agency_id = $item['agency_id'];
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
            
        } else {
            // Sản phẩm của admin: 100% cho admin
            $admin_balance += $item_total;
        }
    }
    $order_items_stmt->close();
    
    // 5. Cộng BACoin cho admin (nếu có)
    if ($admin_balance > 0) {
        // Lấy admin_id từ config
        $admin_id = ADMIN_USER_ID;
        
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
    }

    // 6. Cập nhật trạng thái thanh toán của đơn hàng
    $sql = "UPDATE payments SET status = 'paid', paid_at = NOW(), payment_method = 'BACoin', amount_bacoin = ? WHERE order_id = ?";
    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        throw new Exception('Lỗi prepare update payments: ' . $conn->error);
    }
    $stmt->bind_param("di", $total_amount, $order_id);
    if (!$stmt->execute()) {
        throw new Exception('Lỗi khi cập nhật trạng thái thanh toán: ' . $stmt->error);
    }
    $stmt->close();
    
    // Chỉ cập nhật total_amount_bacoin khi thanh toán bằng BACoin
    $update_order_bacoin_sql = "UPDATE orders SET total_amount_bacoin = ? WHERE id = ?";
    $update_order_bacoin_stmt = $conn->prepare($update_order_bacoin_sql);
    $update_order_bacoin_stmt->bind_param("di", $total_amount, $order_id);
    $update_order_bacoin_stmt->execute();
    $update_order_bacoin_stmt->close();

    // Commit transaction
    if (!$conn->commit()) {
        throw new Exception('Lỗi khi commit transaction: ' . $conn->error);
    }

    // Debug log thành công
    error_log("DEBUG BACOIN: Thanh toán thành công. User ID: $user_id, New Balance: $new_balance");
    
    http_response_code(200);
    echo json_encode([
        'success' => true, 
        'message' => 'Thanh toán thành công', 
        'new_balance' => $new_balance,
        'amount_deducted' => $total_amount,
        'bacoin_distribution' => [
            'admin_received' => $admin_balance,
            'agency_received' => $agency_balance,
            'total_distributed' => $admin_balance + $agency_balance
        ]
    ]);
} catch (Exception $e) {
    $conn->rollback();
    error_log("DEBUG BACOIN ERROR: " . $e->getMessage());
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}  