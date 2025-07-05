<?php
// Comprehensive database setup for the order system
require_once 'config/db_connect.php';

echo "=== DATABASE SETUP FOR ORDER SYSTEM ===\n\n";

// Step 1: Create addresses table
echo "Step 1: Creating addresses table...\n";
$sql = "
CREATE TABLE IF NOT EXISTS `addresses` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `address_line` varchar(255) NOT NULL,
  `city` varchar(100) NOT NULL,
  `province` varchar(100) NOT NULL,
  `postal_code` varchar(20) DEFAULT NULL,
  `is_default` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `addresses_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
";

if ($conn->query($sql) === TRUE) {
    echo "✓ Addresses table created successfully\n";
} else {
    echo "✗ Error creating addresses table: " . $conn->error . "\n";
}

// Step 2: Create orders table
echo "\nStep 2: Creating orders table...\n";
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

// Step 3: Create order_items table
echo "\nStep 3: Creating order_items table...\n";
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

// Step 4: Create payments table
echo "\nStep 4: Creating payments table...\n";
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

// Step 5: Create bacoin_transactions table
echo "\nStep 5: Creating bacoin_transactions table...\n";
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

// Step 6: Add balance column to users table
echo "\nStep 6: Adding balance column to users table...\n";
$result = $conn->query("SHOW COLUMNS FROM users LIKE 'balance'");
if ($result->num_rows == 0) {
    $sql = "ALTER TABLE users ADD COLUMN balance DECIMAL(10,2) DEFAULT 0.00";
    if ($conn->query($sql) === TRUE) {
        echo "✓ Balance column added to users table\n";
    } else {
        echo "✗ Error adding balance column: " . $conn->error . "\n";
    }
} else {
    echo "✓ Balance column already exists in users table\n";
}

// Step 7: Add sample addresses for existing users
echo "\nStep 7: Adding sample addresses...\n";
$users = $conn->query("SELECT id, username FROM users");
if ($users) {
    while ($user = $users->fetch_assoc()) {
        $user_id = $user['id'];
        
        // Check if user already has an address
        $existing = $conn->query("SELECT id FROM user_addresses WHERE user_id = $user_id LIMIT 1");
        if ($existing->num_rows == 0) {
            // Add a default address for this user
            $insert_sql = "INSERT INTO addresses (user_id, address_line, city, province, is_default) VALUES (?, ?, ?, ?, 1)";
            $stmt = $conn->prepare($insert_sql);
            $address_line = "123 Main Street";
            $city = "Ho Chi Minh City";
            $province = "Ho Chi Minh";
            $stmt->bind_param("isss", $user_id, $address_line, $city, $province);
            
            if ($stmt->execute()) {
                echo "✓ Added default address for user: {$user['username']} (ID: $user_id)\n";
            } else {
                echo "✗ Failed to add address for user: {$user['username']} (ID: $user_id)\n";
            }
            $stmt->close();
        } else {
            echo "✓ User {$user['username']} already has an address\n";
        }
    }
}

// Step 8: Add initial BACoin balance to users
echo "\nStep 8: Adding initial BACoin balance...\n";
$update_sql = "UPDATE users SET balance = 1000.00 WHERE role = 'user'";
if ($conn->query($update_sql) === TRUE) {
    echo "✓ Added initial BACoin balance to users\n";
} else {
    echo "✗ Error adding BACoin balance: " . $conn->error . "\n";
}

// Step 9: Check if products table has required columns
echo "\nStep 9: Checking products table structure...\n";
$result = $conn->query("SHOW COLUMNS FROM products LIKE 'is_agency_product'");
if ($result->num_rows == 0) {
    echo "Adding is_agency_product column to products table...\n";
    $sql = "ALTER TABLE products ADD COLUMN is_agency_product BOOLEAN DEFAULT FALSE";
    if ($conn->query($sql) === TRUE) {
        echo "✓ is_agency_product column added to products table\n";
    } else {
        echo "✗ Error adding is_agency_product column: " . $conn->error . "\n";
    }
} else {
    echo "✓ is_agency_product column already exists in products table\n";
}

$result = $conn->query("SHOW COLUMNS FROM products LIKE 'platform_fee_rate'");
if ($result->num_rows == 0) {
    echo "Adding platform_fee_rate column to products table...\n";
    $sql = "ALTER TABLE products ADD COLUMN platform_fee_rate DECIMAL(5,2) DEFAULT 20.00";
    if ($conn->query($sql) === TRUE) {
        echo "✓ platform_fee_rate column added to products table\n";
    } else {
        echo "✗ Error adding platform_fee_rate column: " . $conn->error . "\n";
    }
} else {
    echo "✓ platform_fee_rate column already exists in products table\n";
}

$result = $conn->query("SHOW COLUMNS FROM products LIKE 'agency_id'");
if ($result->num_rows == 0) {
    echo "Adding agency_id column to products table...\n";
    $sql = "ALTER TABLE products ADD COLUMN agency_id INT NULL";
    if ($conn->query($sql) === TRUE) {
        echo "✓ agency_id column added to products table\n";
    } else {
        echo "✗ Error adding agency_id column: " . $conn->error . "\n";
    }
} else {
    echo "✓ agency_id column already exists in products table\n";
}

echo "\n=== DATABASE SETUP COMPLETE ===\n";
echo "\nNow you can test the order API with valid data!\n";
?> 