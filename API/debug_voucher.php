<?php
// Debug file để kiểm tra lỗi
error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Content-Type: application/json');

try {
    // Test kết nối database
    require_once 'config/db_connect.php';
    echo "Database connection: OK\n";
    
    // Test query đơn giản
    $sql = "SELECT COUNT(*) as count FROM vouchers";
    $result = $conn->query($sql);
    if ($result) {
        $row = $result->fetch_assoc();
        echo "Vouchers count: " . $row['count'] . "\n";
    } else {
        echo "Database query failed: " . $conn->error . "\n";
    }
    
    // Test với dữ liệu thực
    $user_id = 4;
    $cart_total = 65000;
    $cart_quantity = 1;
    
    // Lấy voucher có hiệu lực
    $sql = "SELECT 
                v.id,
                v.voucher_code,
                v.discount_amount,
                v.quantity,
                v.start_date,
                v.end_date,
                v.status,
                v.min_quantity,
                v.min_total_amount
            FROM vouchers v
            WHERE v.status = 'active' 
            AND v.quantity > 0
            AND v.start_date <= NOW()
            AND v.end_date >= NOW()
            ORDER BY v.discount_amount DESC";
    
    $result = $conn->query($sql);
    
    if (!$result) {
        throw new Exception("Database query failed: " . $conn->error);
    }
    
    $vouchers = [];
    while ($row = $result->fetch_assoc()) {
        $vouchers[] = $row;
    }
    
    echo "Found " . count($vouchers) . " active vouchers\n";
    
    foreach ($vouchers as $voucher) {
        echo "Voucher: " . $voucher['voucher_code'] . 
             " - Min Qty: " . $voucher['min_quantity'] . 
             " - Min Amount: " . $voucher['min_total_amount'] . "\n";
    }
    
    // Test logic điều kiện
    $available_vouchers = [];
    
    foreach ($vouchers as $voucher) {
        $meets_quantity = $cart_quantity >= $voucher['min_quantity'];
        $meets_amount = $cart_total >= $voucher['min_total_amount'];
        
        echo "Voucher " . $voucher['voucher_code'] . ":\n";
        echo "  - Cart quantity: $cart_quantity, Required: " . $voucher['min_quantity'] . " -> " . ($meets_quantity ? "OK" : "FAIL") . "\n";
        echo "  - Cart total: $cart_total, Required: " . $voucher['min_total_amount'] . " -> " . ($meets_amount ? "OK" : "FAIL") . "\n";
        
        $voucher_data = [
            'id' => (int)$voucher['id'],
            'voucher_code' => $voucher['voucher_code'],
            'discount_amount' => (float)$voucher['discount_amount'],
            'min_quantity' => (int)$voucher['min_quantity'],
            'min_total_amount' => (float)$voucher['min_total_amount'],
            'is_available' => $meets_quantity && $meets_amount,
            'meets_quantity' => $meets_quantity,
            'meets_amount' => $meets_amount
        ];
        
        $available_vouchers[] = $voucher_data;
    }
    
    echo "\nFinal result:\n";
    echo json_encode($available_vouchers, JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
    echo "Stack trace: " . $e->getTraceAsString() . "\n";
}
?> 