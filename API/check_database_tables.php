<?php
// Check database tables and structure
require_once 'config/db_connect.php';

echo "=== DATABASE TABLES CHECK ===\n\n";

// List of required tables
$required_tables = [
    'users',
    'addresses', 
    'products',
    'product_variant',
    'orders',
    'order_items',
    'payments',
    'bacoin_transactions',
    'product_combinations',
    'product_combination_items'
];

foreach ($required_tables as $table) {
    echo "Checking table: $table\n";
    $result = $conn->query("SHOW TABLES LIKE '$table'");
    if ($result && $result->num_rows > 0) {
        echo "✓ Table '$table' exists\n";
        
        // Check row count
        $count_result = $conn->query("SELECT COUNT(*) as count FROM $table");
        if ($count_result) {
            $count = $count_result->fetch_assoc()['count'];
            echo "  - Row count: $count\n";
        }
        
        // Show table structure
        $structure_result = $conn->query("DESCRIBE $table");
        if ($structure_result) {
            echo "  - Columns:\n";
            while ($column = $structure_result->fetch_assoc()) {
                echo "    * {$column['Field']} ({$column['Type']}) - {$column['Null']} - {$column['Key']}\n";
            }
        }
    } else {
        echo "✗ Table '$table' does NOT exist!\n";
    }
    echo "\n";
}

// Check specific foreign key relationships
echo "=== FOREIGN KEY CHECKS ===\n\n";

// Check if users table has the required columns
$user_columns = $conn->query("SHOW COLUMNS FROM users");
if ($user_columns) {
    $columns = [];
    while ($col = $user_columns->fetch_assoc()) {
        $columns[] = $col['Field'];
    }
    
    echo "Users table columns: " . implode(', ', $columns) . "\n";
    
    if (!in_array('balance', $columns)) {
        echo "⚠ WARNING: 'balance' column missing from users table!\n";
    }
}

// Check if orders table has the required columns
$order_columns = $conn->query("SHOW COLUMNS FROM orders");
if ($order_columns) {
    $columns = [];
    while ($col = $order_columns->fetch_assoc()) {
        $columns[] = $col['Field'];
    }
    
    echo "Orders table columns: " . implode(', ', $columns) . "\n";
    
    if (!in_array('total_amount_bacoin', $columns)) {
        echo "⚠ WARNING: 'total_amount_bacoin' column missing from orders table!\n";
    }
}

// Check if payments table has the required columns
$payment_columns = $conn->query("SHOW COLUMNS FROM payments");
if ($payment_columns) {
    $columns = [];
    while ($col = $payment_columns->fetch_assoc()) {
        $columns[] = $col['Field'];
    }
    
    echo "Payments table columns: " . implode(', ', $columns) . "\n";
    
    if (!in_array('amount_bacoin', $columns)) {
        echo "⚠ WARNING: 'amount_bacoin' column missing from payments table!\n";
    }
}

echo "\n=== CHECK COMPLETE ===\n";
?> 