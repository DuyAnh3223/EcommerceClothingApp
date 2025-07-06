<?php
header('Content-Type: text/html; charset=utf-8');
require_once 'config/db_connect.php';

echo "<h1>🧪 Test Real Flutter Request with Voucher TEST2</h1>";

// Simulate real Flutter request
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

// Check voucher before test
echo "<h2>2. Check Voucher TEST2 Before Test</h2>";
$voucher_before_sql = "
    SELECT 
        v.id,
        v.voucher_code,
        v.quantity,
        (SELECT COUNT(*) FROM voucher_usage WHERE voucher_id = v.id) as used_count
    FROM vouchers v
    WHERE v.voucher_code = 'TEST2'
";

$voucher_before_result = mysqli_query($conn, $voucher_before_sql);

if ($voucher_before_result && mysqli_num_rows($voucher_before_result) > 0) {
    $voucher_before_data = mysqli_fetch_assoc($voucher_before_result);
    $remaining_before = $voucher_before_data['quantity'] - $voucher_before_data['used_count'];
    
    echo "<p><strong>Voucher:</strong> {$voucher_before_data['voucher_code']}</p>";
    echo "<p><strong>Total Quantity:</strong> {$voucher_before_data['quantity']}</p>";
    echo "<p><strong>Used Count:</strong> {$voucher_before_data['used_count']}</p>";
    echo "<p><strong>Remaining:</strong> $remaining_before</p>";
}

// Simulate the exact API call
echo "<h2>3. Simulate API Call</h2>";

// Parse request like the API does
$input = $flutter_request;
$user_id = isset($input['user_id']) ? (int)$input['user_id'] : null;
$address_id = isset($input['address_id']) ? (int)$input['address_id'] : null;
$payment_method = isset($input['payment_method']) ? $input['payment_method'] : null;
$cart_items = isset($input['cart_items']) ? $input['cart_items'] : [];

// Voucher parameters
$voucher_id = isset($input['voucher_id']) ? (int)$input['voucher_id'] : null;
$voucher_code = isset($input['voucher_code']) ? $input['voucher_code'] : null;
$discount_amount = isset($input['discount_amount']) ? (float)$input['discount_amount'] : 0.0;

echo "<p><strong>Parsed voucher data:</strong></p>";
echo "<p>voucher_id: $voucher_id</p>";
echo "<p>voucher_code: $voucher_code</p>";
echo "<p>discount_amount: $discount_amount</p>";

// Start transaction
mysqli_begin_transaction($conn);

try {
    // Calculate order total (simplified)
    $total_amount = 100000; // Simulate 100,000 VNĐ order
    $original_total = $total_amount;
    $final_total = $total_amount;
    $voucher_applied = false;
    $voucher_discount = 0;
    
    echo "<p><strong>Original Total:</strong> " . number_format($total_amount) . " VNĐ</p>";
    
    // Apply voucher discount (exact logic from API)
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
    
    // Create order (exact logic from API)
    $order_sql = "INSERT INTO orders (user_id, address_id, total_amount, platform_fee, status, voucher_id) VALUES (?, ?, ?, 0, 'pending', ?)";
    $order_stmt = $conn->prepare($order_sql);
    $order_stmt->bind_param("iidd", $user_id, $address_id, $final_total, $voucher_id);
    $order_stmt->execute();
    $order_id = $order_stmt->insert_id;
    $order_stmt->close();
    
    echo "<p style='color: green;'><strong>Order created:</strong> ID=$order_id</p>";
    
    // Record voucher usage (exact logic from API)
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

// Check voucher after test
echo "<h2>4. Check Voucher TEST2 After Test</h2>";
$voucher_after_sql = "
    SELECT 
        v.id,
        v.voucher_code,
        v.quantity,
        (SELECT COUNT(*) FROM voucher_usage WHERE voucher_id = v.id) as used_count
    FROM vouchers v
    WHERE v.voucher_code = 'TEST2'
";

$voucher_after_result = mysqli_query($conn, $voucher_after_sql);

if ($voucher_after_result && mysqli_num_rows($voucher_after_result) > 0) {
    $voucher_after_data = mysqli_fetch_assoc($voucher_after_result);
    $remaining_after = $voucher_after_data['quantity'] - $voucher_after_data['used_count'];
    
    echo "<p><strong>Voucher:</strong> {$voucher_after_data['voucher_code']}</p>";
    echo "<p><strong>Total Quantity:</strong> {$voucher_after_data['quantity']}</p>";
    echo "<p><strong>Used Count:</strong> {$voucher_after_data['used_count']}</p>";
    echo "<p><strong>Remaining:</strong> $remaining_after</p>";
    
    if ($remaining_after < $remaining_before) {
        echo "<p style='color: green;'><strong>✅ Voucher quantity decreased correctly!</strong></p>";
        echo "<p><strong>Decrease:</strong> " . ($remaining_before - $remaining_after) . " units</p>";
    } else {
        echo "<p style='color: red;'><strong>❌ Voucher quantity did not decrease!</strong></p>";
    }
}

// Check latest orders with voucher
echo "<h2>5. Check Latest Orders with TEST2 Voucher</h2>";
$latest_orders_sql = "
    SELECT 
        o.id,
        o.user_id,
        o.total_amount,
        o.voucher_id,
        o.created_at,
        v.voucher_code
    FROM orders o
    LEFT JOIN vouchers v ON o.voucher_id = v.id
    WHERE v.voucher_code = 'TEST2'
    ORDER BY o.created_at DESC
    LIMIT 5
";

$latest_orders_result = mysqli_query($conn, $latest_orders_sql);

if ($latest_orders_result && mysqli_num_rows($latest_orders_result) > 0) {
    echo "<p><strong>Latest orders with TEST2 voucher:</strong></p>";
    echo "<table border='1' style='border-collapse: collapse; width: 100%;'>";
    echo "<tr><th>Order ID</th><th>User ID</th><th>Total Amount</th><th>Voucher ID</th><th>Created At</th></tr>";
    
    while ($order = mysqli_fetch_assoc($latest_orders_result)) {
        echo "<tr>";
        echo "<td>{$order['id']}</td>";
        echo "<td>{$order['user_id']}</td>";
        echo "<td>" . number_format($order['total_amount']) . " VNĐ</td>";
        echo "<td>{$order['voucher_id']}</td>";
        echo "<td>{$order['created_at']}</td>";
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "<p style='color: orange;'>⚠️ No orders found with TEST2 voucher</p>";
}

mysqli_close($conn);
?> 