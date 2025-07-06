<?php
include_once 'config/db_connect.php';

echo "=== Fixing Voucher Timing Issues ===\n";

// Check current time
$now = new DateTime();
echo "Current time: " . $now->format('Y-m-d H:i:s') . "\n";

// Fix voucher GIAM20K timing
$voucher_code = 'GIAM20K';

// Get current voucher details
$check_sql = "SELECT id, voucher_code, start_date, end_date, status FROM vouchers WHERE voucher_code = ?";
$check_stmt = $conn->prepare($check_sql);
$check_stmt->bind_param("s", $voucher_code);
$check_stmt->execute();
$result = $check_stmt->get_result();

if ($result->num_rows > 0) {
    $voucher = $result->fetch_assoc();
    echo "\nCurrent voucher details:\n";
    echo json_encode($voucher, JSON_PRETTY_PRINT) . "\n";
    
    // Check if start_date is in the future
    $start_date = new DateTime($voucher['start_date']);
    if ($start_date > $now) {
        echo "\nVoucher start_date is in the future. Fixing...\n";
        
        // Update start_date to be 1 hour ago
        $new_start_date = $now->format('Y-m-d H:i:s');
        
        $update_sql = "UPDATE vouchers SET start_date = ? WHERE voucher_code = ?";
        $update_stmt = $conn->prepare($update_sql);
        $update_stmt->bind_param("ss", $new_start_date, $voucher_code);
        
        if ($update_stmt->execute()) {
            echo "✓ Voucher start_date updated successfully\n";
            
            // Verify the update
            $check_stmt->execute();
            $result = $check_stmt->get_result();
            $updated_voucher = $result->fetch_assoc();
            
            echo "\nUpdated voucher details:\n";
            echo json_encode($updated_voucher, JSON_PRETTY_PRINT) . "\n";
            
            // Test validation
            $new_start = new DateTime($updated_voucher['start_date']);
            $end_date = new DateTime($updated_voucher['end_date']);
            
            if ($now >= $new_start && $now <= $end_date) {
                echo "✓ Voucher is now valid!\n";
            } else {
                echo "✗ Voucher still has timing issues\n";
            }
        } else {
            echo "✗ Failed to update voucher: " . $update_stmt->error . "\n";
        }
        $update_stmt->close();
    } else {
        echo "✓ Voucher start_date is already valid\n";
    }
} else {
    echo "✗ Voucher not found\n";
}

$check_stmt->close();
$conn->close();
?> 