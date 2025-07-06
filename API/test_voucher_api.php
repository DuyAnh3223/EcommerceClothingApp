<?php
// Test script for Voucher API
header('Content-Type: text/html; charset=utf-8');

echo "<h1>🧪 Test Voucher API</h1>";

// Test database connection
require_once 'config/db_connect.php';
if ($conn) {
    echo "<p style='color: green;'>✓ Database connection successful</p>";
} else {
    echo "<p style='color: red;'>✗ Database connection failed</p>";
    exit;
}

// Test get vouchers
echo "<h2>Testing GET Vouchers API</h2>";
try {
    $stmt = $conn->prepare("SELECT * FROM vouchers ORDER BY created_at DESC");
    $stmt->execute();
    $result = $stmt->get_result();
    $vouchers = [];
    while ($row = $result->fetch_assoc()) {
        $vouchers[] = $row;
    }
    
    echo "<p style='color: green;'>✓ Found " . count($vouchers) . " vouchers</p>";
    
    if (count($vouchers) > 0) {
        echo "<h3>Vouchers in database:</h3>";
        echo "<table border='1' style='border-collapse: collapse; width: 100%;'>";
        echo "<tr><th>ID</th><th>Voucher Code</th><th>Discount Amount</th><th>Quantity</th><th>Start Date</th><th>End Date</th></tr>";
        
        foreach ($vouchers as $voucher) {
            echo "<tr>";
            echo "<td>{$voucher['id']}</td>";
            echo "<td>{$voucher['voucher_code']}</td>";
            echo "<td>" . number_format($voucher['discount_amount']) . " VNĐ</td>";
            echo "<td>{$voucher['quantity']}</td>";
            echo "<td>{$voucher['start_date']}</td>";
            echo "<td>{$voucher['end_date']}</td>";
            echo "</tr>";
        }
        echo "</table>";
    }
    
} catch (Exception $e) {
    echo "<p style='color: red;'>✗ Error: " . $e->getMessage() . "</p>";
}

// Test authentication
echo "<h2>Testing Authentication</h2>";
require_once 'utils/auth.php';
$user = authenticate();
if ($user) {
    echo "<p style='color: green;'>✓ Authentication successful - User ID: {$user['id']}, Role: {$user['role']}</p>";
} else {
    echo "<p style='color: red;'>✗ Authentication failed</p>";
}

// Test API endpoint directly
echo "<h2>Testing API Endpoint</h2>";
echo "<p>Testing: <code>admin/vouchers/get_vouchers.php</code></p>";

// Simulate the API call
$_SERVER['REQUEST_METHOD'] = 'GET';
$_SESSION['user_id'] = 6; // Admin user ID
$_SESSION['role'] = 'admin';

ob_start();
include 'admin/vouchers/get_vouchers.php';
$api_output = ob_get_clean();

echo "<h3>API Response:</h3>";
echo "<pre style='background: #f5f5f5; padding: 10px; border-radius: 5px;'>";
echo htmlspecialchars($api_output);
echo "</pre>";

// Test JSON parsing
$json_data = json_decode($api_output, true);
if ($json_data) {
    echo "<p style='color: green;'>✓ JSON response is valid</p>";
    if (isset($json_data['success']) && $json_data['success'] == 200) {
        echo "<p style='color: green;'>✓ API returned success status</p>";
        if (isset($json_data['data']) && is_array($json_data['data'])) {
            echo "<p style='color: green;'>✓ API returned " . count($json_data['data']) . " vouchers</p>";
        }
    } else {
        echo "<p style='color: red;'>✗ API returned error: " . ($json_data['message'] ?? 'Unknown error') . "</p>";
    }
} else {
    echo "<p style='color: red;'>✗ Invalid JSON response</p>";
}

echo "<h2>Manual API Test</h2>";
echo "<p>You can also test the API manually by visiting:</p>";
echo "<p><a href='admin/vouchers/get_vouchers.php' target='_blank'>http://localhost/EcommerceClothingApp/API/admin/vouchers/get_vouchers.php</a></p>";

echo "<h2>Voucher Validation Test</h2>";
echo "<p>Test voucher validation:</p>";
echo "<p><a href='vouchers/validate_voucher.php' target='_blank'>http://localhost/EcommerceClothingApp/API/vouchers/validate_voucher.php</a></p>";

echo "<h2>Flutter Web Test</h2>";
echo "<p>To test with Flutter web, run:</p>";
echo "<code>flutter run -d chrome --web-port=8080</code>";
echo "<p>Then open: <a href='http://localhost:8080' target='_blank'>http://localhost:8080</a></p>";

// Test data
$test_data = [
    'voucher_code' => 'GIAM20K',
    'product_ids' => [4] // Product ID 4
];

echo "<h2>1. Test Data</h2>";
echo "<pre>" . json_encode($test_data, JSON_PRETTY_PRINT) . "</pre>";

// Simulate API call
echo "<h2>2. Simulate API Call</h2>";

$voucherCode = mysqli_real_escape_string($conn, $test_data['voucher_code']);
$productIds = array_map('intval', $test_data['product_ids']);
$productIdsStr = implode(',', $productIds);

echo "<p><strong>Voucher Code:</strong> $voucherCode</p>";
echo "<p><strong>Product IDs:</strong> " . implode(', ', $productIds) . "</p>";

// Get voucher details
$voucherQuery = "
    SELECT 
        v.id,
        v.voucher_code,
        v.discount_amount,
        v.quantity,
        v.start_date,
        v.end_date,
        v.voucher_type,
        v.category_filter,
        COUNT(vu.id) as used_count
    FROM vouchers v
    LEFT JOIN voucher_usage vu ON v.id = vu.voucher_id
    WHERE v.voucher_code = '$voucherCode'
    GROUP BY v.id
";

$voucherResult = mysqli_query($conn, $voucherQuery);

if (!$voucherResult || mysqli_num_rows($voucherResult) === 0) {
    echo "<p style='color: red;'>❌ Voucher không tồn tại</p>";
    exit;
}

$voucher = mysqli_fetch_assoc($voucherResult);

echo "<h2>3. Voucher Details</h2>";
echo "<p><strong>Voucher ID:</strong> {$voucher['id']}</p>";
echo "<p><strong>Code:</strong> {$voucher['voucher_code']}</p>";
echo "<p><strong>Discount:</strong> " . number_format($voucher['discount_amount']) . " VNĐ</p>";
echo "<p><strong>Quantity:</strong> {$voucher['quantity']}</p>";
echo "<p><strong>Used Count:</strong> {$voucher['used_count']}</p>";
echo "<p><strong>Remaining:</strong> " . ($voucher['quantity'] - $voucher['used_count']) . "</p>";

// Check voucher validity
$now = new DateTime();
$startDate = new DateTime($voucher['start_date']);
$endDate = new DateTime($voucher['end_date']);

echo "<h2>4. Voucher Validity</h2>";
echo "<p><strong>Current Time:</strong> " . $now->format('Y-m-d H:i:s') . "</p>";
echo "<p><strong>Start Date:</strong> " . $startDate->format('Y-m-d H:i:s') . "</p>";
echo "<p><strong>End Date:</strong> " . $endDate->format('Y-m-d H:i:s') . "</p>";

if ($now < $startDate) {
    echo "<p style='color: red;'>❌ Voucher chưa có hiệu lực</p>";
    exit;
}

if ($now > $endDate) {
    echo "<p style='color: red;'>❌ Voucher đã hết hiệu lực</p>";
    exit;
}

echo "<p style='color: green;'>✅ Voucher còn hiệu lực</p>";

// Check remaining quantity
$remainingQuantity = $voucher['quantity'] - $voucher['used_count'];
if ($remainingQuantity <= 0) {
    echo "<p style='color: red;'>❌ Voucher đã hết số lượng</p>";
    exit;
}

echo "<p style='color: green;'>✅ Voucher còn số lượng</p>";

// Check product applicability
$applicableProducts = [];
$totalDiscount = 0;

switch ($voucher['voucher_type']) {
    case 'all_products':
        $applicableProducts = $productIds;
        $totalDiscount = $voucher['discount_amount'] * count($productIds);
        break;
        
    case 'specific_products':
        $assocQuery = "
            SELECT product_id 
            FROM voucher_product_associations 
            WHERE voucher_id = {$voucher['id']} 
            AND product_id IN ($productIdsStr)
        ";
        $assocResult = mysqli_query($conn, $assocQuery);
        
        while ($row = mysqli_fetch_assoc($assocResult)) {
            $applicableProducts[] = $row['product_id'];
        }
        
        if (!empty($applicableProducts)) {
            $totalDiscount = $voucher['discount_amount'] * count($applicableProducts);
        }
        break;
        
    case 'category_based':
        $categoryFilter = mysqli_real_escape_string($conn, $voucher['category_filter']);
        $categoryQuery = "
            SELECT id 
            FROM products 
            WHERE id IN ($productIdsStr) 
            AND category = '$categoryFilter'
        ";
        $categoryResult = mysqli_query($conn, $categoryQuery);
        
        while ($row = mysqli_fetch_assoc($categoryResult)) {
            $applicableProducts[] = $row['id'];
        }
        
        if (!empty($applicableProducts)) {
            $totalDiscount = $voucher['discount_amount'] * count($applicableProducts);
        }
        break;
}

echo "<h2>5. Product Applicability</h2>";
echo "<p><strong>Voucher Type:</strong> {$voucher['voucher_type']}</p>";
echo "<p><strong>Applicable Products:</strong> " . implode(', ', $applicableProducts) . "</p>";
echo "<p><strong>Total Discount:</strong> " . number_format($totalDiscount) . " VNĐ</p>";

if (empty($applicableProducts)) {
    echo "<p style='color: red;'>❌ Voucher không áp dụng được cho sản phẩm đã chọn</p>";
    exit;
}

echo "<p style='color: green;'>✅ Voucher áp dụng được cho sản phẩm</p>";

// Return validation result
$result = [
    'voucher_id' => (int)$voucher['id'],
    'voucher_code' => $voucher['voucher_code'],
    'discount_amount' => (float)$voucher['discount_amount'],
    'total_discount' => $totalDiscount,
    'applicable_products' => $applicableProducts,
    'remaining_quantity' => $remainingQuantity,
    'voucher_type' => $voucher['voucher_type'],
    'category_filter' => $voucher['category_filter']
];

echo "<h2>6. API Response</h2>";
echo "<p><strong>Success Response:</strong></p>";
echo "<pre>" . json_encode([
    'success' => true,
    'message' => 'Voucher hợp lệ',
    'data' => $result
], JSON_PRETTY_PRINT) . "</pre>";

echo "<h2>7. Voucher ID Check</h2>";
echo "<p><strong>Voucher ID in response:</strong> {$result['voucher_id']}</p>";
echo "<p><strong>Voucher ID type:</strong> " . gettype($result['voucher_id']) . "</p>";

mysqli_close($conn);
?> 