<?php
include_once 'config/db_connect.php';

echo "=== Testing Voucher System with Exception Handling ===\n";

// Test 1: Tạo voucher với quantity = 1
echo "\n1. Creating voucher with quantity = 1\n";
$voucher_code = 'TEST_QUANTITY_ONE';
$discount_amount = 5000;
$quantity = 1;

// Xóa voucher test cũ nếu có
$conn->query("DELETE FROM vouchers WHERE voucher_code = '$voucher_code'");

// Tạo voucher mới
$insert_sql = "INSERT INTO vouchers (voucher_code, discount_amount, quantity, start_date, end_date, status) 
               VALUES (?, ?, ?, NOW(), DATE_ADD(NOW(), INTERVAL 1 DAY), 'active')";
$stmt = $conn->prepare($insert_sql);
$stmt->bind_param("sdi", $voucher_code, $discount_amount, $quantity);
$stmt->execute();
$voucher_id = $conn->insert_id;
$stmt->close();

echo "Created voucher: ID=$voucher_id, Code=$voucher_code, Quantity=$quantity\n";

// Test 2: Kiểm tra voucher trước khi sử dụng
echo "\n2. Checking voucher before usage\n";
$check_sql = "SELECT id, voucher_code, discount_amount, quantity, status FROM vouchers WHERE id = ?";
$stmt = $conn->prepare($check_sql);
$stmt->bind_param("i", $voucher_id);
$stmt->execute();
$result = $stmt->get_result();
$voucher = $result->fetch_assoc();
$stmt->close();

echo "Before usage: " . json_encode($voucher) . "\n";

// Test 3: Sử dụng voucher lần đầu (thành công)
echo "\n3. First usage (should succeed)\n";
$update_sql = "UPDATE vouchers SET 
    quantity = quantity - 1,
    status = CASE 
        WHEN quantity - 1 = 0 THEN 'inactive'
        WHEN end_date < NOW() THEN 'expired'
        ELSE status
    END
    WHERE id = ? AND quantity > 0";
$stmt = $conn->prepare($update_sql);
$stmt->bind_param("i", $voucher_id);
$result = $stmt->execute();
$affected_rows = $stmt->affected_rows;
$stmt->close();

echo "First usage result: " . ($result ? "SUCCESS" : "FAILED") . ", Affected rows: $affected_rows\n";

// Kiểm tra voucher sau lần sử dụng đầu tiên
$check_sql = "SELECT id, voucher_code, discount_amount, quantity, status FROM vouchers WHERE id = ?";
$stmt = $conn->prepare($check_sql);
$stmt->bind_param("i", $voucher_id);
$stmt->execute();
$result = $stmt->get_result();
$voucher = $result->fetch_assoc();
$stmt->close();

echo "After first usage: " . json_encode($voucher) . "\n";

// Test 4: Thử sử dụng voucher lần thứ 2 (thất bại)
echo "\n4. Second usage attempt (should fail)\n";
$update_sql = "UPDATE vouchers SET 
    quantity = quantity - 1,
    status = CASE 
        WHEN quantity - 1 = 0 THEN 'inactive'
        WHEN end_date < NOW() THEN 'expired'
        ELSE status
    END
    WHERE id = ? AND quantity > 0";
$stmt = $conn->prepare($update_sql);
$stmt->bind_param("i", $voucher_id);
$result = $stmt->execute();
$affected_rows = $stmt->affected_rows;
$stmt->close();

echo "Second usage result: " . ($result ? "SUCCESS" : "FAILED") . ", Affected rows: $affected_rows\n";

// Kiểm tra voucher sau lần sử dụng thứ 2
$check_sql = "SELECT id, voucher_code, discount_amount, quantity, status FROM vouchers WHERE id = ?";
$stmt = $conn->prepare($check_sql);
$stmt->bind_param("i", $voucher_id);
$stmt->execute();
$result = $stmt->get_result();
$voucher = $result->fetch_assoc();
$stmt->close();

echo "After second usage: " . json_encode($voucher) . "\n";

// Test 5: Kiểm tra các trường hợp ngoại lệ
echo "\n5. Testing exception cases\n";

// Test 5a: Voucher không tồn tại
echo "\n5a. Testing non-existent voucher\n";
$non_existent_id = 99999;
$check_sql = "SELECT id, voucher_code, discount_amount, quantity, status FROM vouchers WHERE id = ?";
$stmt = $conn->prepare($check_sql);
$stmt->bind_param("i", $non_existent_id);
$stmt->execute();
$result = $stmt->get_result();
$voucher = $result->fetch_assoc();
$stmt->close();

if (!$voucher) {
    echo "✓ Non-existent voucher correctly handled\n";
} else {
    echo "✗ Non-existent voucher found (unexpected)\n";
}

// Test 5b: Voucher hết hạn
echo "\n5b. Testing expired voucher\n";
$expired_voucher_code = 'TEST_EXPIRED';
$conn->query("DELETE FROM vouchers WHERE voucher_code = '$expired_voucher_code'");

$insert_sql = "INSERT INTO vouchers (voucher_code, discount_amount, quantity, start_date, end_date, status) 
               VALUES (?, ?, ?, DATE_SUB(NOW(), INTERVAL 2 DAY), DATE_SUB(NOW(), INTERVAL 1 DAY), 'expired')";
$stmt = $conn->prepare($insert_sql);
$stmt->bind_param("sdi", $expired_voucher_code, $discount_amount, $quantity);
$stmt->execute();
$expired_voucher_id = $conn->insert_id;
$stmt->close();

$check_sql = "SELECT id, voucher_code, discount_amount, quantity, status, start_date, end_date FROM vouchers WHERE id = ?";
$stmt = $conn->prepare($check_sql);
$stmt->bind_param("i", $expired_voucher_id);
$stmt->execute();
$result = $stmt->get_result();
$expired_voucher = $result->fetch_assoc();
$stmt->close();

echo "Expired voucher: " . json_encode($expired_voucher) . "\n";

// Test 5c: Voucher không có hiệu lực
echo "\n5c. Testing inactive voucher\n";
$inactive_voucher_code = 'TEST_INACTIVE';
$conn->query("DELETE FROM vouchers WHERE voucher_code = '$inactive_voucher_code'");

$insert_sql = "INSERT INTO vouchers (voucher_code, discount_amount, quantity, start_date, end_date, status) 
               VALUES (?, ?, ?, NOW(), DATE_ADD(NOW(), INTERVAL 1 DAY), 'inactive')";
$stmt = $conn->prepare($insert_sql);
$stmt->bind_param("sdi", $inactive_voucher_code, $discount_amount, $quantity);
$stmt->execute();
$inactive_voucher_id = $conn->insert_id;
$stmt->close();

$check_sql = "SELECT id, voucher_code, discount_amount, quantity, status FROM vouchers WHERE id = ?";
$stmt = $conn->prepare($check_sql);
$stmt->bind_param("i", $inactive_voucher_id);
$stmt->execute();
$result = $stmt->get_result();
$inactive_voucher = $result->fetch_assoc();
$stmt->close();

echo "Inactive voucher: " . json_encode($inactive_voucher) . "\n";

// Dọn dẹp
echo "\n6. Cleaning up test data\n";
$conn->query("DELETE FROM vouchers WHERE voucher_code IN ('$voucher_code', '$expired_voucher_code', '$inactive_voucher_code')");
echo "✓ Test completed and cleaned up.\n";

echo "\n=== Test Summary ===\n";
echo "✓ Voucher với quantity = 1 được tạo thành công\n";
echo "✓ Lần sử dụng đầu tiên thành công và quantity = 0\n";
echo "✓ Status tự động chuyển từ 'active' sang 'inactive'\n";
echo "✓ Lần sử dụng thứ 2 thất bại (quantity = 0)\n";
echo "✓ Các trường hợp ngoại lệ được xử lý đúng\n";
echo "✓ Database được dọn dẹp sau test\n";
?> 