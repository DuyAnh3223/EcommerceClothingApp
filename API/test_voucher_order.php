<?php
header('Content-Type: text/html; charset=utf-8');
require_once 'config/db_connect.php';

echo "<h1>🧪 Test Voucher Order</h1>";

// Test data - mô phỏng request từ Flutter
$test_data = [
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
    'voucher_id' => 11, // GIAM20K
    'voucher_code' => 'GIAM20K',
    'discount_amount' => 20000
];

echo "<h2>1. Test Data</h2>";
echo "<pre>" . json_encode($test_data, JSON_PRETTY_PRINT) . "</pre>";

// Simulate the API call
echo "<h2>2. Simulating API Call</h2>";

// Parse input like the API does
$input = $test_data;
$user_id = isset($input['user_id']) ? (int)$input['user_id'] : null;
$address_id = isset($input['address_id']) ? (int)$input['address_id'] : null;
$payment_method = isset($input['payment_method']) ? $input['payment_method'] : null;
$cart_items = isset($input['cart_items']) ? $input['cart_items'] : [];

// Voucher parameters
$voucher_id = isset($input['voucher_id']) ? (int)$input['voucher_id'] : null;
$voucher_code = isset($input['voucher_code']) ? $input['voucher_code'] : null;
$discount_amount = isset($input['discount_amount']) ? (float)$input['discount_amount'] : 0.0;

echo "<p><strong>Parsed Voucher Data:</strong></p>";
echo "<p>voucher_id: $voucher_id</p>";
echo "<p>voucher_code: $voucher_code</p>";
echo "<p>discount_amount: $discount_amount</p>";

// Check voucher before processing
echo "<h2>3. Check Voucher Before Processing</h2>";
$voucher_sql = "
    SELECT 
        v.id,
        v.voucher_code,
        v.discount_amount,
        v.quantity,
        (SELECT COUNT(*) FROM voucher_usage WHERE voucher_id = v.id) as used_count
    FROM vouchers v
    WHERE v.id = ?
";

$voucher_stmt = mysqli_prepare($conn, $voucher_sql);
mysqli_stmt_bind_param($voucher_stmt, "i", $voucher_id);
mysqli_stmt_execute($voucher_stmt);
$voucher_result = mysqli_stmt_get_result($voucher_stmt);

if ($voucher_result && mysqli_num_rows($voucher_result) > 0) {
    $voucher_data = mysqli_fetch_assoc($voucher_result);
    $remaining_quantity = $voucher_data['quantity'] - $voucher_data['used_count'];
    
    echo "<p><strong>Voucher Found:</strong></p>";
    echo "<p>ID: {$voucher_data['id']}</p>";
    echo "<p>Code: {$voucher_data['voucher_code']}</p>";
    echo "<p>Discount: " . number_format($voucher_data['discount_amount']) . " VNĐ</p>";
    echo "<p>Total Quantity: {$voucher_data['quantity']}</p>";
    echo "<p>Used Count: {$voucher_data['used_count']}</p>";
    echo "<p>Remaining: $remaining_quantity</p>";
    
    if ($remaining_quantity > 0) {
        echo "<p style='color: green;'>✅ Voucher có thể sử dụng</p>";
    } else {
        echo "<p style='color: red;'>❌ Voucher đã hết số lượng</p>";
    }
} else {
    echo "<p style='color: red;'>❌ Voucher không tồn tại</p>";
}

mysqli_stmt_close($voucher_stmt);

// Calculate order total
echo "<h2>4. Calculate Order Total</h2>";
$total_amount = 0;
$total_platform_fee = 0;

foreach ($cart_items as $cart_item) {
    $product_id = (int)$cart_item['product_id'];
    $variant_id = (int)$cart_item['variant_id'];
    $quantity = (int)$cart_item['quantity'];
    
    // Get product price
    $stmt = mysqli_prepare($conn, "
        SELECT p.is_agency_product, p.platform_fee_rate, pv.price, pv.stock 
        FROM products p 
        JOIN product_variant pv ON p.id = pv.product_id 
        WHERE p.id = ? AND pv.variant_id = ? AND p.status = 'active' AND pv.status = 'active'
    ");
    mysqli_stmt_bind_param($stmt, "ii", $product_id, $variant_id);
    mysqli_stmt_execute($stmt);
    $result = mysqli_stmt_get_result($stmt);
    
    if (mysqli_num_rows($result) > 0) {
        $product_info = mysqli_fetch_assoc($result);
        $base_price = (float)$product_info['price'];
        $is_agency_product = (bool)$product_info['is_agency_product'];
        $platform_fee_rate = (float)$product_info['platform_fee_rate'];
        
        $item_total = $base_price * $quantity;
        $item_platform_fee = 0;
        
        if ($is_agency_product) {
            $item_platform_fee = $item_total * ($platform_fee_rate / 100);
        }
        
        $total_amount += $item_total + $item_platform_fee;
        $total_platform_fee += $item_platform_fee;
        
        echo "<p>Product $product_id: " . number_format($item_total) . " VNĐ (Platform Fee: " . number_format($item_platform_fee) . " VNĐ)</p>";
    }
    mysqli_stmt_close($stmt);
}

echo "<p><strong>Original Total:</strong> " . number_format($total_amount) . " VNĐ</p>";
echo "<p><strong>Platform Fee:</strong> " . number_format($total_platform_fee) . " VNĐ</p>";

// Apply voucher discount
echo "<h2>5. Apply Voucher Discount</h2>";
$original_total = $total_amount;
$final_total = $total_amount;
$voucher_applied = false;
$voucher_discount = 0;

if ($voucher_id && $discount_amount > 0) {
    $voucher_stmt = mysqli_prepare($conn, $voucher_sql);
    mysqli_stmt_bind_param($voucher_stmt, "i", $voucher_id);
    mysqli_stmt_execute($voucher_stmt);
    $voucher_result = mysqli_stmt_get_result($voucher_stmt);
    
    if (mysqli_num_rows($voucher_result) > 0) {
        $voucher_data = mysqli_fetch_assoc($voucher_result);
        $remaining_quantity = $voucher_data['quantity'] - $voucher_data['used_count'];
        
        if ($remaining_quantity > 0) {
            $final_total = $total_amount - $discount_amount;
            if ($final_total < 0) $final_total = 0;
            
            $voucher_applied = true;
            $voucher_discount = $discount_amount;
            
            echo "<p style='color: green;'>✅ Voucher applied successfully!</p>";
            echo "<p><strong>Original Total:</strong> " . number_format($original_total) . " VNĐ</p>";
            echo "<p><strong>Discount:</strong> " . number_format($discount_amount) . " VNĐ</p>";
            echo "<p><strong>Final Total:</strong> " . number_format($final_total) . " VNĐ</p>";
        } else {
            echo "<p style='color: red;'>❌ Voucher has no remaining quantity</p>";
        }
    } else {
        echo "<p style='color: red;'>❌ Voucher not found</p>";
    }
    mysqli_stmt_close($voucher_stmt);
}

// Simulate order creation
echo "<h2>6. Simulate Order Creation</h2>";

mysqli_begin_transaction($conn);

try {
    // Create order
    $order_sql = "INSERT INTO orders (user_id, address_id, total_amount, platform_fee, status, voucher_id) VALUES (?, ?, ?, ?, 'pending', ?)";
    $order_stmt = mysqli_prepare($conn, $order_sql);
    mysqli_stmt_bind_param($order_stmt, "iiddi", $user_id, $address_id, $final_total, $total_platform_fee, $voucher_id);
    mysqli_stmt_execute($order_stmt);
    $order_id = mysqli_insert_id($conn);
    mysqli_stmt_close($order_stmt);
    
    echo "<p style='color: green;'>✅ Order created with ID: $order_id</p>";
    
    // Record voucher usage
    if ($voucher_applied && $voucher_id) {
        $usage_sql = "INSERT INTO voucher_usage (voucher_id, user_id, order_id, discount_applied) VALUES (?, ?, ?, ?)";
        $usage_stmt = mysqli_prepare($conn, $usage_sql);
        mysqli_stmt_bind_param($usage_stmt, "iiid", $voucher_id, $user_id, $order_id, $voucher_discount);
        mysqli_stmt_execute($usage_stmt);
        mysqli_stmt_close($usage_stmt);
        
        echo "<p style='color: green;'>✅ Voucher usage recorded</p>";
    }
    
    // Add order items
    foreach ($cart_items as $item) {
        $product_id = (int)$item['product_id'];
        $variant_id = (int)$item['variant_id'];
        $quantity = (int)$item['quantity'];
        
        $price_sql = "SELECT price FROM product_variant WHERE product_id = ? AND variant_id = ?";
        $price_stmt = mysqli_prepare($conn, $price_sql);
        mysqli_stmt_bind_param($price_stmt, "ii", $product_id, $variant_id);
        mysqli_stmt_execute($price_stmt);
        $price_result = mysqli_stmt_get_result($price_stmt);
        $price_data = mysqli_fetch_assoc($price_result);
        
        $item_sql = "INSERT INTO order_items (order_id, product_id, variant_id, quantity, price, platform_fee) VALUES (?, ?, ?, ?, ?, 0)";
        $item_stmt = mysqli_prepare($conn, $item_sql);
        mysqli_stmt_bind_param($item_stmt, "iiidd", $order_id, $product_id, $variant_id, $quantity, $price_data['price']);
        mysqli_stmt_execute($item_stmt);
        mysqli_stmt_close($item_stmt);
    }
    
    // Add payment
    $pay_sql = "INSERT INTO payments (order_id, payment_method, amount, status) VALUES (?, ?, ?, 'pending')";
    $pay_stmt = mysqli_prepare($conn, $pay_sql);
    mysqli_stmt_bind_param($pay_stmt, "isd", $order_id, $payment_method, $final_total);
    mysqli_stmt_execute($pay_stmt);
    mysqli_stmt_close($pay_stmt);
    
    mysqli_commit($conn);
    echo "<p style='color: green;'>✅ Transaction committed successfully</p>";
    
} catch (Exception $e) {
    mysqli_rollback($conn);
    echo "<p style='color: red;'>❌ Error: " . $e->getMessage() . "</p>";
}

// Check voucher after order
echo "<h2>7. Check Voucher After Order</h2>";
$voucher_after_sql = "
    SELECT 
        v.id,
        v.voucher_code,
        v.discount_amount,
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
    
    if ($remaining_after < $remaining_quantity) {
        echo "<p style='color: green;'>✅ Voucher quantity decreased correctly!</p>";
    } else {
        echo "<p style='color: red;'>❌ Voucher quantity did not decrease!</p>";
    }
}

mysqli_close($conn);
?> 