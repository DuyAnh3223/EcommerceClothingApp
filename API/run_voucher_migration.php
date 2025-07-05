<?php
require_once 'config/db_connect.php';

echo "Bắt đầu migration cho voucher system...\n";

try {
    // 1. Tạo bảng voucher_product_associations
    echo "1. Tạo bảng voucher_product_associations...\n";
    $createTableQuery = "
        CREATE TABLE IF NOT EXISTS `voucher_product_associations` (
          `id` int(11) NOT NULL AUTO_INCREMENT,
          `voucher_id` int(11) NOT NULL,
          `product_id` int(11) NOT NULL,
          `created_at` datetime DEFAULT current_timestamp(),
          PRIMARY KEY (`id`),
          UNIQUE KEY `unique_voucher_product` (`voucher_id`, `product_id`),
          KEY `voucher_id` (`voucher_id`),
          KEY `product_id` (`product_id`),
          CONSTRAINT `voucher_product_associations_ibfk_1` FOREIGN KEY (`voucher_id`) REFERENCES `vouchers` (`id`) ON DELETE CASCADE,
          CONSTRAINT `voucher_product_associations_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ";
    
    if (mysqli_query($conn, $createTableQuery)) {
        echo "✓ Bảng voucher_product_associations đã được tạo thành công\n";
    } else {
        echo "✗ Lỗi tạo bảng voucher_product_associations: " . mysqli_error($conn) . "\n";
    }
    
    // 2. Thêm cột voucher_type và category_filter vào bảng vouchers
    echo "2. Thêm cột voucher_type và category_filter...\n";
    
    // Kiểm tra xem cột voucher_type đã tồn tại chưa
    $checkColumnQuery = "SHOW COLUMNS FROM vouchers LIKE 'voucher_type'";
    $checkResult = mysqli_query($conn, $checkColumnQuery);
    
    if (mysqli_num_rows($checkResult) == 0) {
        $addVoucherTypeQuery = "ALTER TABLE `vouchers` ADD COLUMN `voucher_type` enum('all_products','specific_products','category_based') DEFAULT 'all_products' AFTER `end_date`";
        if (mysqli_query($conn, $addVoucherTypeQuery)) {
            echo "✓ Cột voucher_type đã được thêm thành công\n";
        } else {
            echo "✗ Lỗi thêm cột voucher_type: " . mysqli_error($conn) . "\n";
        }
    } else {
        echo "✓ Cột voucher_type đã tồn tại\n";
    }
    
    // Kiểm tra xem cột category_filter đã tồn tại chưa
    $checkCategoryQuery = "SHOW COLUMNS FROM vouchers LIKE 'category_filter'";
    $checkCategoryResult = mysqli_query($conn, $checkCategoryQuery);
    
    if (mysqli_num_rows($checkCategoryResult) == 0) {
        $addCategoryFilterQuery = "ALTER TABLE `vouchers` ADD COLUMN `category_filter` varchar(100) DEFAULT NULL AFTER `voucher_type`";
        if (mysqli_query($conn, $addCategoryFilterQuery)) {
            echo "✓ Cột category_filter đã được thêm thành công\n";
        } else {
            echo "✗ Lỗi thêm cột category_filter: " . mysqli_error($conn) . "\n";
        }
    } else {
        echo "✓ Cột category_filter đã tồn tại\n";
    }
    
    // 3. Cập nhật dữ liệu hiện có
    echo "3. Cập nhật dữ liệu hiện có...\n";
    $updateQuery = "UPDATE `vouchers` SET `voucher_type` = 'all_products' WHERE `voucher_type` IS NULL";
    if (mysqli_query($conn, $updateQuery)) {
        echo "✓ Dữ liệu hiện có đã được cập nhật\n";
    } else {
        echo "✗ Lỗi cập nhật dữ liệu: " . mysqli_error($conn) . "\n";
    }
    
    echo "\n🎉 Migration hoàn thành thành công!\n";
    echo "Bây giờ bạn có thể:\n";
    echo "- Tạo voucher cho tất cả sản phẩm\n";
    echo "- Tạo voucher cho sản phẩm cụ thể\n";
    echo "- Tạo voucher theo danh mục sản phẩm\n";
    
} catch (Exception $e) {
    echo "✗ Lỗi migration: " . $e->getMessage() . "\n";
}

mysqli_close($conn);
?> 