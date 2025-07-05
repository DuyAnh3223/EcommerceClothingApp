<?php
// Create missing tables for the order system
require_once 'config/db_connect.php';

echo "=== CREATING MISSING TABLES ===\n\n";

// Check if orders table exists
$result = $conn->query("SHOW TABLES LIKE 'orders'");
if ($result->num_rows == 0) {
    echo "Creating orders table...\n";
    $sql = "
    CREATE TABLE IF NOT EXISTS `orders` (
      `id` int(11) NOT NULL AUTO_INCREMENT,
      `user_id` int(11) NOT NULL,
      `address_id` int(11) NOT NULL,
      `total_amount` decimal(10,2) DEFAULT 0.00,
      `total_amount_bacoin` decimal(10,2) DEFAULT 0.00,
      `platform_fee` decimal(10,2) DEFAULT 0.00,
      `status` enum('pending','confirmed','shipped','delivered','cancelled') DEFAULT 'pending',
      `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      PRIMARY KEY (`id`),
      KEY `user_id` (`user_id`),
      KEY `address_id` (`address_id`),
      CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
      CONSTRAINT `orders_ibfk_2` FOREIGN KEY (`address_id`) REFERENCES `addresses` (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ";
    
    if ($conn->query($sql) === TRUE) {
        echo "✓ Orders table created successfully\n";
    } else {
        echo "✗ Error creating orders table: " . $conn->error . "\n";
    }
} else {
    echo "✓ Orders table already exists\n";
}

// Check if order_items table exists
$result = $conn->query("SHOW TABLES LIKE 'order_items'");
if ($result->num_rows == 0) {
    echo "Creating order_items table...\n";
    $sql = "
    CREATE TABLE IF NOT EXISTS `order_items` (
      `id` int(11) NOT NULL AUTO_INCREMENT,
      `order_id` int(11) NOT NULL,
      `product_id` int(11) NOT NULL,
      `variant_id` int(11) NOT NULL,
      `quantity` int(11) NOT NULL,
      `price` decimal(10,2) NOT NULL,
      `platform_fee` decimal(10,2) DEFAULT 0.00,
      `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (`id`),
      KEY `order_id` (`order_id`),
      KEY `product_id` (`product_id`),
      CONSTRAINT `order_items_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE,
      CONSTRAINT `order_items_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ";
    
    if ($conn->query($sql) === TRUE) {
        echo "✓ Order_items table created successfully\n";
    } else {
        echo "✗ Error creating order_items table: " . $conn->error . "\n";
    }
} else {
    echo "✓ Order_items table already exists\n";
}

// Check if payments table exists
$result = $conn->query("SHOW TABLES LIKE 'payments'");
if ($result->num_rows == 0) {
    echo "Creating payments table...\n";
    $sql = "
    CREATE TABLE IF NOT EXISTS `payments` (
      `id` int(11) NOT NULL AUTO_INCREMENT,
      `order_id` int(11) NOT NULL,
      `payment_method` varchar(50) NOT NULL,
      `amount` decimal(10,2) NOT NULL,
      `amount_bacoin` decimal(10,2) DEFAULT 0.00,
      `status` enum('pending','paid','failed','refunded') DEFAULT 'pending',
      `transaction_code` varchar(100) DEFAULT NULL,
      `paid_at` timestamp NULL DEFAULT NULL,
      `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (`id`),
      KEY `order_id` (`order_id`),
      CONSTRAINT `payments_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ";
    
    if ($conn->query($sql) === TRUE) {
        echo "✓ Payments table created successfully\n";
    } else {
        echo "✗ Error creating payments table: " . $conn->error . "\n";
    }
} else {
    echo "✓ Payments table already exists\n";
}

// Check if bacoin_transactions table exists
$result = $conn->query("SHOW TABLES LIKE 'bacoin_transactions'");
if ($result->num_rows == 0) {
    echo "Creating bacoin_transactions table...\n";
    $sql = "
    CREATE TABLE IF NOT EXISTS `bacoin_transactions` (
      `id` int(11) NOT NULL AUTO_INCREMENT,
      `user_id` int(11) NOT NULL,
      `amount` decimal(10,2) NOT NULL,
      `type` enum('spend','receive') NOT NULL,
      `description` text,
      `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (`id`),
      KEY `user_id` (`user_id`),
      CONSTRAINT `bacoin_transactions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ";
    
    if ($conn->query($sql) === TRUE) {
        echo "✓ Bacoin_transactions table created successfully\n";
    } else {
        echo "✗ Error creating bacoin_transactions table: " . $conn->error . "\n";
    }
} else {
    echo "✓ Bacoin_transactions table already exists\n";
}

// Check if users table has balance column
$result = $conn->query("SHOW COLUMNS FROM users LIKE 'balance'");
if ($result->num_rows == 0) {
    echo "Adding balance column to users table...\n";
    $sql = "ALTER TABLE users ADD COLUMN balance DECIMAL(10,2) DEFAULT 0.00";
    
    if ($conn->query($sql) === TRUE) {
        echo "✓ Balance column added to users table\n";
        
        // Add some initial BACoin to users for testing
        $update_sql = "UPDATE users SET balance = 1000.00 WHERE role = 'user'";
        if ($conn->query($update_sql) === TRUE) {
            echo "✓ Added initial BACoin balance to users\n";
        }
    } else {
        echo "✗ Error adding balance column: " . $conn->error . "\n";
    }
} else {
    echo "✓ Balance column already exists in users table\n";
}

echo "\n=== MISSING TABLES CREATION COMPLETE ===\n";
?> 