<?php
header('Content-Type: text/html; charset=utf-8');
require_once 'config/db_connect.php';

echo "<h1>🧪 Test Voucher Scenarios</h1>";

// Test different voucher scenarios
$scenarios = [
    [
        'name' => 'Scenario 1: No voucher data',
        'request' => [
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
            ]
        ]
    ],
    [
        'name' => 'Scenario 2: Correct voucher data',
        'request' => [
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
            'voucher_id' => 10,
            'voucher_code' => 'TEST2',
            'discount_amount' => 5000
        ]
    ],
    [
        'name' => 'Scenario 3: Voucher ID as string',
        'request' => [
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
            'voucher_id' => '10',
            'voucher_code' => 'TEST2',
            'discount_amount' => 5000
        ]
    ],
    [
        'name' => 'Scenario 4: Missing voucher_id',
        'request' => [
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
            'voucher_code' => 'TEST2',
            'discount_amount' => 5000
        ]
    ],
    [
        'name' => 'Scenario 5: Wrong voucher_id',
        'request' => [
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
            'voucher_id' => 999, // Wrong ID
            'voucher_code' => 'TEST2',
            'discount_amount' => 5000
        ]
    ],
    [
        'name' => 'Scenario 6: Zero discount_amount',
        'request' => [
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
            'voucher_id' => 10,
            'voucher_code' => 'TEST2',
            'discount_amount' => 0
        ]
    ]
];

foreach ($scenarios as $index => $scenario) {
    echo "<h2>" . ($index + 1) . ". " . $scenario['name'] . "</h2>";
    
    $input = $scenario['request'];
    
    // Parse voucher data like the API does
    $voucher_id = isset($input['voucher_id']) ? (int)$input['voucher_id'] : null;
    $voucher_code = isset($input['voucher_code']) ? $input['voucher_code'] : null;
    $discount_amount = isset($input['discount_amount']) ? (float)$input['discount_amount'] : 0.0;
    
    echo "<p><strong>Request data:</strong></p>";
    echo "<pre>" . json_encode($input, JSON_PRETTY_PRINT) . "</pre>";
    
    echo "<p><strong>Parsed voucher data:</strong></p>";
    echo "<p>voucher_id: " . ($voucher_id ?? 'NULL') . "</p>";
    echo "<p>voucher_code: " . ($voucher_code ?? 'NULL') . "</p>";
    echo "<p>discount_amount: $discount_amount</p>";
    
    // Test voucher validation
    if ($voucher_id && $discount_amount > 0) {
        $voucher_sql = "SELECT id, voucher_code, discount_amount, quantity, 
                               (SELECT COUNT(*) FROM voucher_usage WHERE voucher_id = vouchers.id) as used_count
                        FROM vouchers WHERE id = ?";
        $voucher_stmt = $conn->prepare($voucher_sql);
        $voucher_stmt->bind_param("i", $voucher_id);
        $voucher_stmt->execute();
        $voucher_result = $voucher_stmt->get_result();
        
        if ($voucher_result->num_rows > 0) {
            $voucher_data = $voucher_result->fetch_assoc();
            $remaining_quantity = $voucher_data['quantity'] - $voucher_data['used_count'];
            
            echo "<p style='color: green;'><strong>✅ Voucher found:</strong> code={$voucher_data['voucher_code']}, remaining=$remaining_quantity</p>";
            
            if ($remaining_quantity > 0) {
                echo "<p style='color: green;'><strong>✅ Voucher can be applied</strong></p>";
            } else {
                echo "<p style='color: red;'><strong>❌ Voucher has no remaining quantity</strong></p>";
            }
        } else {
            echo "<p style='color: red;'><strong>❌ Voucher not found</strong></p>";
        }
        $voucher_stmt->close();
    } else {
        if (!$voucher_id) {
            echo "<p style='color: orange;'><strong>⚠️ No voucher_id provided</strong></p>";
        }
        if ($discount_amount <= 0) {
            echo "<p style='color: orange;'><strong>⚠️ Invalid discount_amount</strong></p>";
        }
    }
    
    echo "<hr>";
}

// Check current voucher TEST2 status
echo "<h2>Current Voucher TEST2 Status</h2>";
$voucher_status_sql = "
    SELECT 
        v.id,
        v.voucher_code,
        v.quantity,
        (SELECT COUNT(*) FROM voucher_usage WHERE voucher_id = v.id) as used_count
    FROM vouchers v
    WHERE v.voucher_code = 'TEST2'
";

$voucher_status_result = mysqli_query($conn, $voucher_status_sql);

if ($voucher_status_result && mysqli_num_rows($voucher_status_result) > 0) {
    $voucher_status = mysqli_fetch_assoc($voucher_status_result);
    $remaining = $voucher_status['quantity'] - $voucher_status['used_count'];
    
    echo "<p><strong>Voucher ID:</strong> {$voucher_status['id']}</p>";
    echo "<p><strong>Code:</strong> {$voucher_status['voucher_code']}</p>";
    echo "<p><strong>Total Quantity:</strong> {$voucher_status['quantity']}</p>";
    echo "<p><strong>Used Count:</strong> {$voucher_status['used_count']}</p>";
    echo "<p><strong>Remaining:</strong> $remaining</p>";
}

echo "<h2>Recommendations</h2>";
echo "<ol>";
echo "<li><strong>Check Flutter logs:</strong> Verify what voucher data is being sent</li>";
echo "<li><strong>Verify voucher_id:</strong> Make sure Flutter sends voucher_id = 10 for TEST2</li>";
echo "<li><strong>Check data types:</strong> Ensure voucher_id is sent as integer, not string</li>";
echo "<li><strong>Verify discount_amount:</strong> Make sure it's greater than 0</li>";
echo "<li><strong>Test with debug logs:</strong> Run the API with debug logs enabled</li>";
echo "</ol>";

mysqli_close($conn);
?> 