<?php
// Sử dụng kết nối database từ thư mục config chính
require_once("../config/db_connect.php");

header('Content-Type: application/json');

// Lấy dữ liệu từ request
$user_id = isset($_POST['user_id']) ? intval($_POST['user_id']) : 0;
$order_id = isset($_POST['order_id']) ? intval($_POST['order_id']) : 0;

if ($user_id <= 0 || $order_id <= 0) {
    echo json_encode(['success' => false, 'message' => 'Thiếu tham số hoặc tham số không hợp lệ']);
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

    // 2. Trừ BACoin vào balance
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

    // 3. Ghi nhận giao dịch vào bacoin_transactions
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

    // 4. Cập nhật trạng thái thanh toán của đơn hàng
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

    // Commit transaction
    if (!$conn->commit()) {
        throw new Exception('Lỗi khi commit transaction: ' . $conn->error);
    }

    // Debug log thành công
    error_log("DEBUG BACOIN: Thanh toán thành công. User ID: $user_id, New Balance: $new_balance");
    
    echo json_encode([
        'success' => true, 
        'message' => 'Thanh toán thành công', 
        'new_balance' => $new_balance,
        'amount_deducted' => $total_amount
    ]);
} catch (Exception $e) {
    $conn->rollback();
    error_log("DEBUG BACOIN ERROR: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}  