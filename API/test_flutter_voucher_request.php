<?php
header('Content-Type: text/html; charset=utf-8');
require_once 'config/db_connect.php';

echo "<h1>🧪 Test Flutter Request with Voucher TEST2</h1>";

// Simulate Flutter request data
$flutter_request = [
    'user_id' => 4,
    'address_id' => 3,
    'payment_method' => 'COD',
    'cart_items' => [
        [
            'type' => 'product',
            'product_id' => 4,
            'variant_id' => 6,
            'quantity' => 1
        ]
    ],
    'voucher_id' => 10, // TEST2
    'voucher_code' => 'TEST2',
    'discount_amount' => 5000
];

echo "<h2>1. Flutter Request Data</h2>";
echo "<pre>" . json_encode($flutter_request, JSON_PRETTY_PRINT) . "</pre>";

// Parse the request like the API does
$input = $flutter_request;
$user_id = isset($input['user_id']) ? (int)$input['user_id'] : null;
$address_id = isset($input['address_id']) ? (int)$input['address_id'] : null;
$payment_method = isset($input['payment_method']) ? $input['payment_method'] : null;
$cart_items = isset($input['cart_items']) ? $input['cart_items'] : [];

// Voucher parameters
$voucher_id = isset($input['voucher_id']) ? (int)$input['voucher_id'] : null;
$voucher_code = isset($input['voucher_code']) ? $input['voucher_code'] : null;
$discount_amount = isset($input['discount_amount']) ? (float)$input['discount_amount'] : 0.0;

echo "<h2>2. Parsed Voucher Data</h2>";
echo "<p><strong>voucher_id:</strong> $voucher_id</p>";
echo "<p><strong>voucher_code:</strong> $voucher_code</p>";
echo "<p><strong>discount_amount:</strong> $discount_amount</p>";

// Check if voucher_id is valid
echo "<h2>3. Validate Voucher ID</h2>";
if ($voucher_id) {
    $voucher_check_sql = "SELECT id, voucher_code FROM vouchers WHERE id = ?";
    $voucher_check_stmt = mysqli_prepare($conn, $voucher_check_sql);
    mysqli_stmt_bind_param($voucher_check_stmt, "i", $voucher_id);
    mysqli_stmt_execute($voucher_check_stmt);
    $voucher_check_result = mysqli_stmt_get_result($voucher_check_stmt);
    
    if (mysqli_num_rows($voucher_check_result) > 0) {
        $voucher_data = mysqli_fetch_assoc($voucher_check_result);
        echo "<p style='color: green;'>✅ Voucher ID $voucher_id is valid (Code: {$voucher_data['voucher_code']})</p>";
    } else {
        echo "<p style='color: red;'>❌ Voucher ID $voucher_id is invalid</p>";
    }
    mysqli_stmt_close($voucher_check_stmt);
} else {
    echo "<p style='color: red;'>❌ voucher_id is null or empty</p>";
}

// Simulate order creation with voucher
echo "<h2>4. Simulate Order Creation</h2>";

mysqli_begin_transaction($conn);

try {
    // Calculate order total (simplified)
    $total_amount = 100000; // Simulate 100,000 VNĐ order
    $final_total = $total_amount - $discount_amount;
    
    echo "<p><strong>Original Total:</strong> " . number_format($total_amount) . " VNĐ</p>";
    echo "<p><strong>Discount:</strong> " . number_format($discount_amount) . " VNĐ</p>";
    echo "<p><strong>Final Total:</strong> " . number_format($final_total) . " VNĐ</p>";
    
    // Create order
    $order_sql = "INSERT INTO orders (user_id, address_id, total_amount, platform_fee, status, voucher_id) VALUES (?, ?, ?, 0, 'pending', ?)";
    $order_stmt = mysqli_prepare($conn, $order_sql);
    mysqli_stmt_bind_param($order_stmt, "iidd", $user_id, $address_id, $final_total, $voucher_id);
    mysqli_stmt_execute($order_stmt);
    $order_id = mysqli_insert_id($conn);
    mysqli_stmt_close($order_stmt);
    
    echo "<p style='color: green;'>✅ Order created with ID: $order_id</p>";
    
    // Record voucher usage
    if ($voucher_id && $discount_amount > 0) {
        $usage_sql = "INSERT INTO voucher_usage (voucher_id, user_id, order_id, discount_applied) VALUES (?, ?, ?, ?)";
        $usage_stmt = mysqli_prepare($conn, $usage_sql);
        mysqli_stmt_bind_param($usage_stmt, "iiid", $voucher_id, $user_id, $order_id, $discount_amount);
        $usage_result = mysqli_stmt_execute($usage_stmt);
        mysqli_stmt_close($usage_stmt);
        
        if ($usage_result) {
            echo "<p style='color: green;'>✅ Voucher usage recorded successfully</p>";
        } else {
            echo "<p style='color: red;'>❌ Failed to record voucher usage: " . mysqli_error($conn) . "</p>";
        }
    } else {
        echo "<p style='color: orange;'>⚠️ No voucher data to record</p>";
    }
    
    // Add payment
    $pay_sql = "INSERT INTO payments (order_id, payment_method, amount, status) VALUES (?, ?, ?, 'pending')";
    $pay_stmt = mysqli_prepare($conn, $pay_sql);
    mysqli_stmt_bind_param($pay_stmt, "isd", $order_id, $payment_method, $final_total);
    mysqli_stmt_execute($pay_stmt);
    mysqli_stmt_close($pay_stmt);
    
    echo "<p style='color: green;'>✅ Payment record created</p>";
    
    mysqli_commit($conn);
    echo "<p style='color: green;'>✅ Transaction committed successfully</p>";
    
} catch (Exception $e) {
    mysqli_rollback($conn);
    echo "<p style='color: red;'>❌ Error: " . $e->getMessage() . "</p>";
}

// Check voucher usage after order
echo "<h2>5. Check Voucher Usage After Order</h2>";
$voucher_after_sql = "
    SELECT 
        v.id,
        v.voucher_code,
        v.quantity,
        (SELECT COUNT(*) FROM voucher_usage WHERE voucher_id = v.id) as used_count
    FROM vouchers v
    WHERE v.id = ?
";

$voucher_after_stmt = mysqli_prepare($conn, $voucher_after_sql);
mysqli_stmt_bind_param($voucher_after_stmt, "i", $voucher_id);
mysqli_stmt_execute($voucher_after_stmt);
$voucher_after_result = mysqli_stmt_get_result($voucher_after_stmt);

if ($voucher_after_result && mysqli_num_rows($voucher_after_result) > 0) {
    $voucher_after_data = mysqli_fetch_assoc($voucher_after_result);
    $remaining_after = $voucher_after_data['quantity'] - $voucher_after_data['used_count'];
    
    echo "<p><strong>Voucher:</strong> {$voucher_after_data['voucher_code']}</p>";
    echo "<p><strong>Total Quantity:</strong> {$voucher_after_data['quantity']}</p>";
    echo "<p><strong>Used Count:</strong> {$voucher_after_data['used_count']}</p>";
    echo "<p><strong>Remaining:</strong> $remaining_after</p>";
    
    if ($remaining_after < 100) {
        echo "<p style='color: green;'>✅ Voucher quantity decreased correctly!</p>";
    } else {
        echo "<p style='color: red;'>❌ Voucher quantity did not decrease!</p>";
    }
}

mysqli_close($conn);
?> 