<?php
header('Content-Type: text/html; charset=utf-8');
require_once 'config/db_connect.php';

echo "<h1>🔍 Test Flutter Voucher Debug</h1>";

// Simulate Flutter request with voucher TEST2
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

echo "<h2>1. Simulate Flutter Request</h2>";
echo "<pre>" . json_encode($flutter_request, JSON_PRETTY_PRINT) . "</pre>";

// Parse request like the API
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

// Check voucher before order
echo "<h2>3. Check Voucher Before Order</h2>";
$voucher_before_sql = "
    SELECT 
        v.id,
        v.voucher_code,
        v.quantity,
        (SELECT COUNT(*) FROM voucher_usage WHERE voucher_id = v.id) as used_count
    FROM vouchers v
    WHERE v.id = ?
";

$voucher_before_stmt = mysqli_prepare($conn, $voucher_before_sql);
mysqli_stmt_bind_param($voucher_before_stmt, "i", $voucher_id);
mysqli_stmt_execute($voucher_before_stmt);
$voucher_before_result = mysqli_stmt_get_result($voucher_before_stmt);

if ($voucher_before_result && mysqli_num_rows($voucher_before_result) > 0) {
    $voucher_before_data = mysqli_fetch_assoc($voucher_before_result);
    $remaining_before = $voucher_before_data['quantity'] - $voucher_before_data['used_count'];
    
    echo "<p><strong>Voucher:</strong> {$voucher_before_data['voucher_code']}</p>";
    echo "<p><strong>Total Quantity:</strong> {$voucher_before_data['quantity']}</p>";
    echo "<p><strong>Used Count:</strong> {$voucher_before_data['used_count']}</p>";
    echo "<p><strong>Remaining:</strong> $remaining_before</p>";
}

// Simulate order creation with voucher
echo "<h2>4. Simulate Order Creation</h2>";

mysqli_begin_transaction($conn);

try {
    // Calculate order total
    $total_amount = 100000; // Simulate 100,000 VNĐ order
    $original_total = $total_amount;
    $final_total = $total_amount;
    $voucher_applied = false;
    $voucher_discount = 0;
    
    echo "<p><strong>Original Total:</strong> " . number_format($total_amount) . " VNĐ</p>";
    
    // Apply voucher discount
    if ($voucher_id && $discount_amount > 0) {
        // Validate voucher
        $voucher_sql = "SELECT id, voucher_code, discount_amount, quantity, 
                               (SELECT COUNT(*) FROM voucher_usage WHERE voucher_id = vouchers.id) as used_count
                        FROM vouchers WHERE id = ?";
        $voucher_stmt = $conn->prepare($voucher_sql);
        $voucher_stmt->bind_param("i", $voucher_id);
        $voucher_stmt->execute();
        $voucher_result = $voucher_stmt->get_result();
        
        echo "<p><strong>Validating voucher:</strong> voucher_id=$voucher_id</p>";
        
        if ($voucher_result->num_rows > 0) {
            $voucher_data = $voucher_result->fetch_assoc();
            $remaining_quantity = $voucher_data['quantity'] - $voucher_data['used_count'];
            
            echo "<p><strong>Voucher found:</strong> code={$voucher_data['voucher_code']}, total_quantity={$voucher_data['quantity']}, used_count={$voucher_data['used_count']}, remaining=$remaining_quantity</p>";
            
            if ($remaining_quantity > 0) {
                // Apply discount
                $final_total = $total_amount - $discount_amount;
                if ($final_total < 0) $final_total = 0;
                
                $voucher_applied = true;
                $voucher_discount = $discount_amount;
                
                echo "<p style='color: green;'><strong>Voucher applied:</strong> voucher_id=$voucher_id, original_total=$original_total, discount_amount=$discount_amount, final_total=$final_total</p>";
            } else {
                echo "<p style='color: red;'><strong>Voucher has no remaining quantity:</strong> remaining=$remaining_quantity</p>";
            }
        } else {
            echo "<p style='color: red;'><strong>Voucher not found:</strong> voucher_id=$voucher_id</p>";
        }
        $voucher_stmt->close();
    } else {
        echo "<p style='color: orange;'><strong>No voucher data or invalid:</strong> voucher_id=$voucher_id, discount_amount=$discount_amount</p>";
    }
    
    echo "<p><strong>Final Total:</strong> " . number_format($final_total) . " VNĐ</p>";
    
    // Create order
    $order_sql = "INSERT INTO orders (user_id, address_id, total_amount, platform_fee, status, voucher_id) VALUES (?, ?, ?, 0, 'pending', ?)";
    $order_stmt = $conn->prepare($order_sql);
    $order_stmt->bind_param("iidd", $user_id, $address_id, $final_total, $voucher_id);
    $order_stmt->execute();
    $order_id = $order_stmt->insert_id;
    $order_stmt->close();
    
    echo "<p style='color: green;'><strong>Order created:</strong> ID=$order_id</p>";
    
    // Record voucher usage
    if ($voucher_applied && $voucher_id) {
        echo "<p><strong>Recording voucher usage:</strong> voucher_id=$voucher_id, user_id=$user_id, order_id=$order_id, discount=$voucher_discount</p>";
        
        $usage_sql = "INSERT INTO voucher_usage (voucher_id, user_id, order_id, discount_applied) VALUES (?, ?, ?, ?)";
        $usage_stmt = $conn->prepare($usage_sql);
        $usage_stmt->bind_param("iiid", $voucher_id, $user_id, $order_id, $voucher_discount);
        $usage_result = $usage_stmt->execute();
        
        if ($usage_result) {
            echo "<p style='color: green;'><strong>Voucher usage recorded successfully:</strong> voucher_id=$voucher_id, order_id=$order_id, discount=$voucher_discount</p>";
        } else {
            echo "<p style='color: red;'><strong>Failed to record voucher usage:</strong> " . $usage_stmt->error . "</p>";
        }
        
        $usage_stmt->close();
    } else {
        echo "<p style='color: orange;'><strong>Skipping voucher usage recording:</strong> voucher_applied=$voucher_applied, voucher_id=$voucher_id</p>";
    }
    
    // Add payment
    $pay_sql = "INSERT INTO payments (order_id, payment_method, amount, status) VALUES (?, ?, ?, 'pending')";
    $pay_stmt = $conn->prepare($pay_sql);
    $pay_stmt->bind_param("isd", $order_id, $payment_method, $final_total);
    $pay_stmt->execute();
    $pay_stmt->close();
    
    echo "<p style='color: green;'><strong>Payment record created</strong></p>";
    
    mysqli_commit($conn);
    echo "<p style='color: green;'><strong>Transaction committed successfully</strong></p>";
    
} catch (Exception $e) {
    mysqli_rollback($conn);
    echo "<p style='color: red;'><strong>Error:</strong> " . $e->getMessage() . "</p>";
}

// Check voucher after order
echo "<h2>5. Check Voucher After Order</h2>";
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
    
    if ($remaining_after < $remaining_before) {
        echo "<p style='color: green;'><strong>✅ Voucher quantity decreased correctly!</strong></p>";
    } else {
        echo "<p style='color: red;'><strong>❌ Voucher quantity did not decrease!</strong></p>";
    }
}

// Check latest voucher usage
echo "<h2>6. Check Latest Voucher Usage</h2>";
$latest_usage_sql = "
    SELECT 
        vu.id,
        vu.voucher_id,
        vu.user_id,
        vu.order_id,
        vu.discount_applied,
        vu.used_at,
        v.voucher_code
    FROM voucher_usage vu
    JOIN vouchers v ON vu.voucher_id = v.id
    WHERE v.voucher_code = 'TEST2'
    ORDER BY vu.used_at DESC
    LIMIT 5
";

$latest_usage_result = mysqli_query($conn, $latest_usage_sql);

if ($latest_usage_result && mysqli_num_rows($latest_usage_result) > 0) {
    echo "<p><strong>Latest voucher usage records:</strong></p>";
    echo "<table border='1' style='border-collapse: collapse; width: 100%;'>";
    echo "<tr><th>ID</th><th>Voucher ID</th><th>User ID</th><th>Order ID</th><th>Discount</th><th>Used At</th></tr>";
    
    while ($usage = mysqli_fetch_assoc($latest_usage_result)) {
        echo "<tr>";
        echo "<td>{$usage['id']}</td>";
        echo "<td>{$usage['voucher_id']}</td>";
        echo "<td>{$usage['user_id']}</td>";
        echo "<td>{$usage['order_id']}</td>";
        echo "<td>" . number_format($usage['discount_applied']) . " VNĐ</td>";
        echo "<td>{$usage['used_at']}</td>";
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "<p style='color: orange;'>⚠️ No voucher usage records found</p>";
}

mysqli_close($conn);
?> 