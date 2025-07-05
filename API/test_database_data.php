<?php
// Check database data for testing
require_once 'config/db_connect.php';

echo "=== DATABASE DATA CHECK ===\n\n";

// Check users
echo "1. Checking users table...\n";
$result = $conn->query("SELECT id, username, email, role FROM users LIMIT 5");
if ($result) {
    while ($row = $result->fetch_assoc()) {
        echo "User ID: {$row['id']}, Username: {$row['username']}, Role: {$row['role']}\n";
    }
} else {
    echo "Error: " . $conn->error . "\n";
}
echo "\n";

// Check addresses
echo "2. Checking addresses table...\n";
$result = $conn->query("SELECT id, user_id, address_line FROM addresses LIMIT 5");
if ($result) {
    while ($row = $result->fetch_assoc()) {
        echo "Address ID: {$row['id']}, User ID: {$row['user_id']}, Address: {$row['address_line']}\n";
    }
} else {
    echo "Error: " . $conn->error . "\n";
}
echo "\n";

// Check products
echo "3. Checking products table...\n";
$result = $conn->query("SELECT id, name, status FROM products WHERE status = 'active' LIMIT 5");
if ($result) {
    while ($row = $result->fetch_assoc()) {
        echo "Product ID: {$row['id']}, Name: {$row['name']}, Status: {$row['status']}\n";
    }
} else {
    echo "Error: " . $conn->error . "\n";
}
echo "\n";

// Check product variants
echo "4. Checking product_variant table...\n";
$result = $conn->query("SELECT product_id, variant_id, price, stock FROM product_variant WHERE status = 'active' LIMIT 5");
if ($result) {
    while ($row = $result->fetch_assoc()) {
        echo "Product ID: {$row['product_id']}, Variant ID: {$row['variant_id']}, Price: {$row['price']}, Stock: {$row['stock']}\n";
    }
} else {
    echo "Error: " . $conn->error . "\n";
}
echo "\n";

// Check product combinations
echo "5. Checking product_combinations table...\n";
$result = $conn->query("SELECT id, name, status FROM product_combinations WHERE status = 'active' LIMIT 5");
if ($result) {
    while ($row = $result->fetch_assoc()) {
        echo "Combination ID: {$row['id']}, Name: {$row['name']}, Status: {$row['status']}\n";
    }
} else {
    echo "Error: " . $conn->error . "\n";
}
echo "\n";

// Check combination items
echo "6. Checking product_combination_items table...\n";
$result = $conn->query("SELECT combination_id, product_id, variant_id, quantity FROM product_combination_items LIMIT 5");
if ($result) {
    while ($row = $result->fetch_assoc()) {
        echo "Combination ID: {$row['combination_id']}, Product ID: {$row['product_id']}, Variant ID: {$row['variant_id']}, Quantity: {$row['quantity']}\n";
    }
} else {
    echo "Error: " . $conn->error . "\n";
}
echo "\n";

echo "=== DATABASE CHECK COMPLETE ===\n";
?> 