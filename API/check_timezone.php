<?php
include_once 'config/db_connect.php';

echo "=== Checking Timezone Issues ===\n";

// Check current timezone settings
echo "PHP timezone: " . date_default_timezone_get() . "\n";
echo "Current PHP time: " . date('Y-m-d H:i:s') . "\n";
echo "Current DateTime: " . (new DateTime())->format('Y-m-d H:i:s') . "\n";

// Check database timezone
$timezone_query = "SELECT @@global.time_zone, @@session.time_zone";
$timezone_result = $conn->query($timezone_query);
if ($timezone_result) {
    $timezone_data = $timezone_result->fetch_assoc();
    echo "MySQL global timezone: " . $timezone_data['@@global.time_zone'] . "\n";
    echo "MySQL session timezone: " . $timezone_data['@@session.time_zone'] . "\n";
}

// Check voucher GIAM20K with different timezone approaches
$voucher_code = 'GIAM20K';
$check_sql = "SELECT id, voucher_code, start_date, end_date, status FROM vouchers WHERE voucher_code = ?";
$check_stmt = $conn->prepare($check_sql);
$check_stmt->bind_param("s", $voucher_code);
$check_stmt->execute();
$result = $check_stmt->get_result();

if ($result->num_rows > 0) {
    $voucher = $result->fetch_assoc();
    echo "\nVoucher GIAM20K details:\n";
    echo json_encode($voucher, JSON_PRETTY_PRINT) . "\n";
    
    // Test with different timezone approaches
    echo "\nTimezone validation tests:\n";
    
    // 1. Current PHP timezone
    $now1 = new DateTime();
    $start1 = new DateTime($voucher['start_date']);
    $end1 = new DateTime($voucher['end_date']);
    
    echo "1. PHP timezone approach:\n";
    echo "   Current: " . $now1->format('Y-m-d H:i:s') . "\n";
    echo "   Start: " . $start1->format('Y-m-d H:i:s') . "\n";
    echo "   End: " . $end1->format('Y-m-d H:i:s') . "\n";
    echo "   Valid: " . ($now1 >= $start1 && $now1 <= $end1 ? 'YES' : 'NO') . "\n";
    
    // 2. Vietnam timezone
    $now2 = new DateTime('now', new DateTimeZone('Asia/Ho_Chi_Minh'));
    $start2 = new DateTime($voucher['start_date'], new DateTimeZone('Asia/Ho_Chi_Minh'));
    $end2 = new DateTime($voucher['end_date'], new DateTimeZone('Asia/Ho_Chi_Minh'));
    
    echo "\n2. Vietnam timezone approach:\n";
    echo "   Current: " . $now2->format('Y-m-d H:i:s') . "\n";
    echo "   Start: " . $start2->format('Y-m-d H:i:s') . "\n";
    echo "   End: " . $end2->format('Y-m-d H:i:s') . "\n";
    echo "   Valid: " . ($now2 >= $start2 && $now2 <= $end2 ? 'YES' : 'NO') . "\n";
    
    // 3. UTC timezone
    $now3 = new DateTime('now', new DateTimeZone('UTC'));
    $start3 = new DateTime($voucher['start_date'], new DateTimeZone('UTC'));
    $end3 = new DateTime($voucher['end_date'], new DateTimeZone('UTC'));
    
    echo "\n3. UTC timezone approach:\n";
    echo "   Current: " . $now3->format('Y-m-d H:i:s') . "\n";
    echo "   Start: " . $start3->format('Y-m-d H:i:s') . "\n";
    echo "   End: " . $end3->format('Y-m-d H:i:s') . "\n";
    echo "   Valid: " . ($now3 >= $start3 && $now3 <= $end3 ? 'YES' : 'NO') . "\n";
}

$check_stmt->close();
$conn->close();
?> 