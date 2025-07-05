<?php
// Create addresses table
require_once 'config/db_connect.php';

echo "=== CREATING ADDRESSES TABLE ===\n\n";

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
    
    // Add some sample addresses for existing users
    $users = $conn->query("SELECT id FROM users LIMIT 3");
    if ($users) {
        while ($user = $users->fetch_assoc()) {
            $user_id = $user['id'];
            
            // Add a default address for each user
            $insert_sql = "INSERT INTO addresses (user_id, address_line, city, province, is_default) VALUES (?, ?, ?, ?, 1)";
            $stmt = $conn->prepare($insert_sql);
            $address_line = "123 Main Street";
            $city = "Ho Chi Minh City";
            $province = "Ho Chi Minh";
            $stmt->bind_param("isss", $user_id, $address_line, $city, $province);
            
            if ($stmt->execute()) {
                echo "✓ Added default address for user ID: $user_id\n";
            } else {
                echo "✗ Failed to add address for user ID: $user_id\n";
            }
            $stmt->close();
        }
    }
    
} else {
    echo "✗ Error creating addresses table: " . $conn->error . "\n";
}

echo "\n=== ADDRESSES TABLE CREATION COMPLETE ===\n";
?> 