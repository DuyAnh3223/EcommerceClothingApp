<?php
include_once 'config/db_connect.php';

echo "=== Checking Voucher TEST2 Status ===\n";

$voucher_code = 'TEST2';

// Get voucher details
$sql = "SELECT id, voucher_code, discount_amount, quantity, status, start_date, end_date FROM vouchers WHERE voucher_code = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $voucher_code);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    $voucher = $result->fetch_assoc();
    echo "Voucher details:\n";
    echo json_encode($voucher, JSON_PRETTY_PRINT) . "\n";
    
    // Check usage count
    $usage_sql = "SELECT COUNT(*) as used_count FROM voucher_usage WHERE voucher_id = ?";
    $usage_stmt = $conn->prepare($usage_sql);
    $usage_stmt->bind_param("i", $voucher['id']);
    $usage_stmt->execute();
    $usage_result = $usage_stmt->get_result();
    $usage = $usage_result->fetch_assoc();
    
    echo "Usage count: " . $usage['used_count'] . "\n";
    echo "Remaining quantity (old logic): " . ($voucher['quantity'] - $usage['used_count']) . "\n";
    echo "Status: " . $voucher['status'] . "\n";
    
    // Check if voucher is currently valid
    $now = new DateTime();
    $start_date = new DateTime($voucher['start_date']);
    $end_date = new DateTime($voucher['end_date']);
    
    echo "Current time: " . $now->format('Y-m-d H:i:s') . "\n";
    echo "Start date: " . $start_date->format('Y-m-d H:i:s') . "\n";
    echo "End date: " . $end_date->format('Y-m-d H:i:s') . "\n";
    
    if ($now >= $start_date && $now <= $end_date && $voucher['status'] == 'active' && $voucher['quantity'] > 0) {
        echo "✓ Voucher should be valid\n";
    } else {
        echo "✗ Voucher is not valid\n";
        if ($now < $start_date) echo "- Not yet active\n";
        if ($now > $end_date) echo "- Expired\n";
        if ($voucher['status'] != 'active') echo "- Status is: " . $voucher['status'] . "\n";
        if ($voucher['quantity'] <= 0) echo "- No quantity left\n";
    }
    
} else {
    echo "Voucher TEST2 not found\n";
}

$conn->close();
?> 