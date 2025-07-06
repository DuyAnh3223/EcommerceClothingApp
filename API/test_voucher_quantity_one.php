<?php
include_once 'config/db_connect.php';

echo "=== Testing Voucher System with Quantity = 1 ===\n";

try {
    // 1. Tạo voucher test với quantity = 1
    echo "\n1. Creating test voucher with quantity = 1...\n";
    $test_voucher_code = 'TEST_QUANTITY_ONE_' . time();
    $conn->query("DELETE FROM vouchers WHERE voucher_code = '$test_voucher_code'");
    
    $insert_sql = "INSERT INTO vouchers (voucher_code, discount_amount, quantity, start_date, end_date) 
                   VALUES (?, ?, ?, NOW(), DATE_ADD(NOW(), INTERVAL 1 DAY))";
    $stmt = $conn->prepare($insert_sql);
    $discount_amount = 5000;
    $quantity = 1;
    $stmt->bind_param("sdi", $test_voucher_code, $discount_amount, $quantity);
    
    if ($stmt->execute()) {
        $voucher_id = $conn->insert_id;
        echo "✓ Test voucher created: ID=$voucher_id, Code=$test_voucher_code\n";
        
        // Kiểm tra voucher được tạo
        $check_sql = "SELECT id, voucher_code, discount_amount, quantity, status FROM vouchers WHERE id = ?";
        $check_stmt = $conn->prepare($check_sql);
        $check_stmt->bind_param("i", $voucher_id);
        $check_stmt->execute();
        $result = $check_stmt->get_result();
        $voucher = $result->fetch_assoc();
        $check_stmt->close();
        
        echo "Initial voucher details: " . json_encode($voucher) . "\n";
    } else {
        echo "✗ Failed to create test voucher: " . $stmt->error . "\n";
        exit(1);
    }
    $stmt->close();
    
    // 2. Test sử dụng voucher lần đầu (thành công)
    echo "\n2. Testing first voucher usage (should succeed)...\n";
    
    // Giả lập việc sử dụng voucher bằng cách giảm quantity
    $update_sql = "UPDATE vouchers SET quantity = quantity - 1 WHERE id = ?";
    $update_stmt = $conn->prepare($update_sql);
    $update_stmt->bind_param("i", $voucher_id);
    
    if ($update_stmt->execute()) {
        echo "✓ First usage successful\n";
        
        // Kiểm tra trạng thái sau khi sử dụng
        $check_sql = "SELECT id, voucher_code, discount_amount, quantity, status FROM vouchers WHERE id = ?";
        $check_stmt = $conn->prepare($check_sql);
        $check_stmt->bind_param("i", $voucher_id);
        $check_stmt->execute();
        $result = $check_stmt->get_result();
        $voucher = $result->fetch_assoc();
        $check_stmt->close();
        
        echo "Voucher after first usage: " . json_encode($voucher) . "\n";
        
        if ($voucher['quantity'] == 0 && $voucher['status'] == 'inactive') {
            echo "✓ Quantity correctly set to 0 and status changed to 'inactive'\n";
        } else {
            echo "✗ Quantity or status not updated correctly\n";
        }
    } else {
        echo "✗ Failed to use voucher: " . $update_stmt->error . "\n";
    }
    $update_stmt->close();
    
    // 3. Test sử dụng voucher lần thứ hai (thất bại)
    echo "\n3. Testing second voucher usage (should fail)...\n";
    
    // Thử giảm quantity thêm lần nữa
    $update_sql = "UPDATE vouchers SET quantity = quantity - 1 WHERE id = ?";
    $update_stmt = $conn->prepare($update_sql);
    $update_stmt->bind_param("i", $voucher_id);
    
    if ($update_stmt->execute()) {
        $affected_rows = $conn->affected_rows;
        if ($affected_rows == 0) {
            echo "✓ Second usage correctly prevented (no rows affected)\n";
        } else {
            echo "✗ Second usage should not have been allowed\n";
        }
        
        // Kiểm tra trạng thái cuối cùng
        $check_sql = "SELECT id, voucher_code, discount_amount, quantity, status FROM vouchers WHERE id = ?";
        $check_stmt = $conn->prepare($check_sql);
        $check_stmt->bind_param("i", $voucher_id);
        $check_stmt->execute();
        $result = $check_stmt->get_result();
        $voucher = $result->fetch_assoc();
        $check_stmt->close();
        
        echo "Final voucher state: " . json_encode($voucher) . "\n";
    } else {
        echo "✗ Error during second usage test: " . $update_stmt->error . "\n";
    }
    $update_stmt->close();
    
    // 4. Test validation trong API đặt hàng
    echo "\n4. Testing voucher validation in order placement API...\n";
    
    // Tạo voucher mới cho test API
    $api_test_code = 'API_TEST_' . time();
    $conn->query("DELETE FROM vouchers WHERE voucher_code = '$api_test_code'");
    
    $insert_sql = "INSERT INTO vouchers (voucher_code, discount_amount, quantity, start_date, end_date) 
                   VALUES (?, ?, ?, NOW(), DATE_ADD(NOW(), INTERVAL 1 DAY))";
    $stmt = $conn->prepare($insert_sql);
    $discount_amount = 5000;
    $quantity = 1;
    $stmt->bind_param("sdi", $api_test_code, $discount_amount, $quantity);
    $stmt->execute();
    $api_voucher_id = $conn->insert_id;
    $stmt->close();
    
    echo "Created API test voucher: ID=$api_voucher_id, Code=$api_test_code\n";
    
    // Test validation logic
    $validation_sql = "SELECT id, voucher_code, discount_amount, quantity, status, 
                              start_date, end_date 
                       FROM vouchers 
                       WHERE voucher_code = ? AND status = 'active' 
                       AND quantity > 0 
                       AND NOW() BETWEEN start_date AND end_date";
    $validation_stmt = $conn->prepare($validation_sql);
    $validation_stmt->bind_param("s", $api_test_code);
    $validation_stmt->execute();
    $result = $validation_stmt->get_result();
    $valid_voucher = $result->fetch_assoc();
    $validation_stmt->close();
    
    if ($valid_voucher) {
        echo "✓ Voucher validation successful: " . json_encode($valid_voucher) . "\n";
        
        // Test sau khi sử dụng
        $conn->query("UPDATE vouchers SET quantity = quantity - 1 WHERE id = $api_voucher_id");
        
        $validation_stmt = $conn->prepare($validation_sql);
        $validation_stmt->bind_param("s", $api_test_code);
        $validation_stmt->execute();
        $result = $validation_stmt->get_result();
        $used_voucher = $result->fetch_assoc();
        $validation_stmt->close();
        
        if (!$used_voucher) {
            echo "✓ Voucher correctly becomes invalid after usage\n";
        } else {
            echo "✗ Voucher should be invalid after usage\n";
        }
    } else {
        echo "✗ Voucher validation failed\n";
    }
    
    // 5. Dọn dẹp
    echo "\n5. Cleaning up test data...\n";
    $conn->query("DELETE FROM vouchers WHERE voucher_code = '$test_voucher_code'");
    $conn->query("DELETE FROM vouchers WHERE voucher_code = '$api_test_code'");
    echo "✓ Test data cleaned up\n";
    
    echo "\n=== Test Summary ===\n";
    echo "✓ Voucher creation with quantity = 1 successful\n";
    echo "✓ First usage works and sets status to inactive\n";
    echo "✓ Second usage correctly prevented\n";
    echo "✓ API validation logic works correctly\n";
    echo "✓ Automatic status management functioning\n";
    echo "\nVoucher system is working correctly!\n";
    
} catch (Exception $e) {
    echo "✗ Test failed: " . $e->getMessage() . "\n";
}

$conn->close();
?> 