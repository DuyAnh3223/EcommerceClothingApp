<?php
header('Content-Type: application/json');
require_once 'config/db_connect.php';

// Test voucher validation
$voucherCode = 'TEST2025';
$productIds = [30, 31]; // Sample product IDs from agency

echo "=== TESTING VOUCHER VALIDATION ===\n";
echo "Voucher Code: $voucherCode\n";
echo "Product IDs: " . implode(', ', $productIds) . "\n";

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
    echo "❌ Voucher not found\n";
    exit;
}

$voucher = mysqli_fetch_assoc($voucherResult);
echo "✅ Voucher found:\n";
echo "- ID: " . $voucher['id'] . "\n";
echo "- Code: " . $voucher['voucher_code'] . "\n";
echo "- Discount: " . $voucher['discount_amount'] . "\n";
echo "- Quantity: " . $voucher['quantity'] . "\n";
echo "- Used: " . $voucher['used_count'] . "\n";
echo "- Start: " . $voucher['start_date'] . "\n";
echo "- End: " . $voucher['end_date'] . "\n";

// Check if voucher is valid
$now = new DateTime();
$startDate = new DateTime($voucher['start_date']);
$endDate = new DateTime($voucher['end_date']);

echo "Current time: " . $now->format('Y-m-d H:i:s') . "\n";
echo "Start date: " . $startDate->format('Y-m-d H:i:s') . "\n";
echo "End date: " . $endDate->format('Y-m-d H:i:s') . "\n";

if ($now < $startDate || $now > $endDate) {
    echo "❌ Voucher is not valid at this time\n";
    exit;
}

echo "✅ Voucher is valid in time range\n";

// Check if voucher has remaining quantity
$remainingQuantity = $voucher['quantity'] - $voucher['used_count'];
if ($remainingQuantity <= 0) {
    echo "❌ Voucher has been fully used\n";
    exit;
}

echo "✅ Voucher has remaining quantity: $remainingQuantity\n";

// Check voucher type and product applicability
$applicableProducts = [];
$totalDiscount = 0;

switch ($voucher['voucher_type']) {
    case 'all_products':
        $applicableProducts = $productIds;
        $totalDiscount = $voucher['discount_amount'] * count($productIds);
        echo "✅ Voucher applies to all products\n";
        break;
        
    default:
        echo "❌ Invalid voucher type\n";
        exit;
}

if (empty($applicableProducts)) {
    echo "❌ Voucher is not applicable to any of the selected products\n";
    exit;
}

echo "✅ Voucher is applicable to products: " . implode(', ', $applicableProducts) . "\n";
echo "✅ Total discount: $totalDiscount VNĐ\n";

echo "\n=== VALIDATION RESULT ===\n";
echo "Success: true\n";
echo "Message: Voucher is valid\n";
echo "Data: {\n";
echo "  voucher_id: " . $voucher['id'] . ",\n";
echo "  voucher_code: " . $voucher['voucher_code'] . ",\n";
echo "  discount_amount: " . $voucher['discount_amount'] . ",\n";
echo "  total_discount: $totalDiscount,\n";
echo "  applicable_products: [" . implode(', ', $applicableProducts) . "],\n";
echo "  remaining_quantity: $remainingQuantity\n";
echo "}\n";

mysqli_close($conn);
?> 