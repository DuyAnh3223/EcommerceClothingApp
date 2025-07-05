<?php
// Test script to check and create vouchers table
header('Content-Type: text/html; charset=utf-8');

echo "<h1>Voucher Table Test</h1>";

// Test database connection
require_once 'config/db_connect.php';
if ($conn) {
    echo "<p style='color: green;'>✓ Database connection successful</p>";
} else {
    echo "<p style='color: red;'>✗ Database connection failed</p>";
    exit;
}

// Check if vouchers table exists
echo "<h2>Checking vouchers table...</h2>";
try {
    $stmt = $conn->prepare("SHOW TABLES LIKE 'vouchers'");
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        echo "<p style='color: green;'>✓ Vouchers table exists</p>";
        
        // Check table structure
        $stmt = $conn->prepare("DESCRIBE vouchers");
        $stmt->execute();
        $result = $stmt->get_result();
        
        echo "<h3>Vouchers table structure:</h3>";
        echo "<table border='1' style='border-collapse: collapse; width: 100%;'>";
        echo "<tr><th>Field</th><th>Type</th><th>Null</th><th>Key</th><th>Default</th><th>Extra</th></tr>";
        
        while ($row = $result->fetch_assoc()) {
            echo "<tr>";
            echo "<td>{$row['Field']}</td>";
            echo "<td>{$row['Type']}</td>";
            echo "<td>{$row['Null']}</td>";
            echo "<td>{$row['Key']}</td>";
            echo "<td>{$row['Default']}</td>";
            echo "<td>{$row['Extra']}</td>";
            echo "</tr>";
        }
        echo "</table>";
        
        // Check if there are any vouchers
        $stmt = $conn->prepare("SELECT COUNT(*) as count FROM vouchers");
        $stmt->execute();
        $result = $stmt->get_result();
        $row = $result->fetch_assoc();
        
        echo "<p>Number of vouchers in database: <strong>{$row['count']}</strong></p>";
        
        if ($row['count'] > 0) {
            echo "<h3>Sample vouchers:</h3>";
            $stmt = $conn->prepare("SELECT * FROM vouchers LIMIT 5");
            $stmt->execute();
            $result = $stmt->get_result();
            
            echo "<table border='1' style='border-collapse: collapse; width: 100%;'>";
            echo "<tr><th>ID</th><th>Voucher Code</th><th>Discount Amount</th><th>Quantity</th><th>Start Date</th><th>End Date</th></tr>";
            
            while ($row = $result->fetch_assoc()) {
                echo "<tr>";
                echo "<td>{$row['id']}</td>";
                echo "<td>{$row['voucher_code']}</td>";
                echo "<td>" . number_format($row['discount_amount']) . " VNĐ</td>";
                echo "<td>{$row['quantity']}</td>";
                echo "<td>{$row['start_date']}</td>";
                echo "<td>{$row['end_date']}</td>";
                echo "</tr>";
            }
            echo "</table>";
        }
        
    } else {
        echo "<p style='color: red;'>✗ Vouchers table does not exist</p>";
        echo "<p>You need to run the SQL script to create the vouchers table.</p>";
        echo "<p>Please run the following SQL commands:</p>";
        echo "<pre>";
        echo "-- Create vouchers table\n";
        echo "CREATE TABLE `vouchers` (\n";
        echo "  `id` int(11) NOT NULL AUTO_INCREMENT,\n";
        echo "  `voucher_code` varchar(50) NOT NULL COMMENT 'Mã voucher',\n";
        echo "  `discount_amount` decimal(15,2) NOT NULL COMMENT 'Số tiền giảm giá',\n";
        echo "  `quantity` int(11) NOT NULL DEFAULT 1 COMMENT 'Số lượng voucher có thể sử dụng',\n";
        echo "  `start_date` datetime NOT NULL COMMENT 'Ngày bắt đầu hiệu lực',\n";
        echo "  `end_date` datetime NOT NULL COMMENT 'Ngày kết thúc hiệu lực',\n";
        echo "  `created_at` datetime DEFAULT current_timestamp(),\n";
        echo "  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),\n";
        echo "  PRIMARY KEY (`id`),\n";
        echo "  UNIQUE KEY `voucher_code` (`voucher_code`)\n";
        echo ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;\n\n";
        echo "-- Create voucher_usage table\n";
        echo "CREATE TABLE `voucher_usage` (\n";
        echo "  `id` int(11) NOT NULL AUTO_INCREMENT,\n";
        echo "  `voucher_id` int(11) NOT NULL,\n";
        echo "  `user_id` int(11) NOT NULL,\n";
        echo "  `order_id` int(11) NOT NULL,\n";
        echo "  `discount_applied` decimal(15,2) NOT NULL,\n";
        echo "  `used_at` datetime DEFAULT current_timestamp(),\n";
        echo "  PRIMARY KEY (`id`),\n";
        echo "  KEY `voucher_id` (`voucher_id`),\n";
        echo "  KEY `user_id` (`user_id`),\n";
        echo "  KEY `order_id` (`order_id`),\n";
        echo "  CONSTRAINT `voucher_usage_ibfk_1` FOREIGN KEY (`voucher_id`) REFERENCES `vouchers` (`id`) ON DELETE CASCADE,\n";
        echo "  CONSTRAINT `voucher_usage_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,\n";
        echo "  CONSTRAINT `voucher_usage_ibfk_3` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE\n";
        echo ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;\n";
        echo "</pre>";
    }
    
} catch (Exception $e) {
    echo "<p style='color: red;'>✗ Error: " . $e->getMessage() . "</p>";
}

// Check voucher_usage table
echo "<h2>Checking voucher_usage table...</h2>";
try {
    $stmt = $conn->prepare("SHOW TABLES LIKE 'voucher_usage'");
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        echo "<p style='color: green;'>✓ Voucher_usage table exists</p>";
    } else {
        echo "<p style='color: red;'>✗ Voucher_usage table does not exist</p>";
    }
    
} catch (Exception $e) {
    echo "<p style='color: red;'>✗ Error: " . $e->getMessage() . "</p>";
}

echo "<h2>Next Steps:</h2>";
echo "<p>1. If tables don't exist, run the SQL script: <code>API/create_voucher_table_fixed.sql</code></p>";
echo "<p>2. Test the voucher API: <a href='test_voucher_api.php'>test_voucher_api.php</a></p>";
echo "<p>3. Access the Flutter admin panel to manage vouchers</p>";
?> 