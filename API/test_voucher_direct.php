<?php
// Direct test script for voucher API
header('Content-Type: text/html; charset=utf-8');

echo "<h1>🎫 Direct Voucher API Test</h1>";

// Test database connection
require_once 'config/db_connect.php';
if ($conn) {
    echo "<p style='color: green;'>✓ Database connection successful</p>";
} else {
    echo "<p style='color: red;'>✗ Database connection failed</p>";
    exit;
}

// Test 1: Check current vouchers
echo "<h2>Test 1: Current Vouchers</h2>";
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

// Test 2: Test adding a voucher
echo "<h2>Test 2: Add Test Voucher</h2>";
try {
    $test_voucher = [
        'voucher_code' => 'TEST' . time(),
        'discount_amount' => 25000,
        'quantity' => 50,
        'start_date' => date('Y-m-d H:i:s'),
        'end_date' => date('Y-m-d H:i:s', strtotime('+30 days'))
    ];
    
    // Check if voucher code already exists
    $stmt = $conn->prepare("SELECT id FROM vouchers WHERE voucher_code = ?");
    $stmt->bind_param("s", $test_voucher['voucher_code']);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->fetch_assoc()) {
        echo "<p style='color: orange;'>⚠ Test voucher already exists, skipping...</p>";
    } else {
        // Add test voucher
        $stmt = $conn->prepare("INSERT INTO vouchers (voucher_code, discount_amount, quantity, start_date, end_date) VALUES (?, ?, ?, ?, ?)");
        $stmt->bind_param("sdiss", 
            $test_voucher['voucher_code'],
            $test_voucher['discount_amount'],
            $test_voucher['quantity'],
            $test_voucher['start_date'],
            $test_voucher['end_date']
        );
        $stmt->execute();
        
        echo "<p style='color: green;'>✓ Test voucher added successfully!</p>";
        echo "<p>Voucher Code: <strong>{$test_voucher['voucher_code']}</strong></p>";
    }
    
} catch (Exception $e) {
    echo "<p style='color: red;'>✗ Error: " . $e->getMessage() . "</p>";
}

// Test 3: Test voucher validation
echo "<h2>Test 3: Validate Voucher</h2>";
try {
    $test_code = 'WELCOME2024';
    $stmt = $conn->prepare("SELECT * FROM vouchers WHERE voucher_code = ?");
    $stmt->bind_param("s", $test_code);
    $stmt->execute();
    $result = $stmt->get_result();
    $voucher = $result->fetch_assoc();
    
    if ($voucher) {
        echo "<p style='color: green;'>✓ Voucher '{$test_code}' found</p>";
        
        $now = new DateTime();
        $start_date = new DateTime($voucher['start_date']);
        $end_date = new DateTime($voucher['end_date']);
        
        if ($now >= $start_date && $now <= $end_date) {
            echo "<p style='color: green;'>✓ Voucher is currently valid</p>";
        } else {
            echo "<p style='color: orange;'>⚠ Voucher is not currently valid</p>";
        }
        
        if ($voucher['quantity'] > 0) {
            echo "<p style='color: green;'>✓ Voucher has quantity available: {$voucher['quantity']}</p>";
        } else {
            echo "<p style='color: red;'>✗ Voucher is out of stock</p>";
        }
    } else {
        echo "<p style='color: red;'>✗ Voucher '{$test_code}' not found</p>";
    }
    
} catch (Exception $e) {
    echo "<p style='color: red;'>✗ Error: " . $e->getMessage() . "</p>";
}

echo "<h2>🎯 Next Steps</h2>";
echo "<p>1. <a href='test_voucher_simple.html' target='_blank'>Open Simple Test Interface</a></p>";
echo "<p>2. <a href='test_complete_voucher_api.php' target='_blank'>Run Complete API Test</a></p>";
echo "<p>3. Access Flutter Admin Panel at <a href='http://localhost:8080' target='_blank'>http://localhost:8080</a></p>";

echo "<h2>📋 Quick Test Links</h2>";
echo "<ul>";
echo "<li><a href='admin/vouchers/get_vouchers.php' target='_blank'>GET Vouchers API</a></li>";
echo "<li><a href='vouchers/validate_voucher.php' target='_blank'>Validate Voucher API</a></li>";
echo "<li><a href='test_voucher_simple.html' target='_blank'>Simple Web Interface</a></li>";
echo "</ul>";
?> 