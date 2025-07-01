-- Tạo bảng product_combinations để lưu thông tin tổ hợp sản phẩm
CREATE TABLE `product_combinations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL COMMENT 'Tên tổ hợp sản phẩm',
  `description` text DEFAULT NULL COMMENT 'Mô tả tổ hợp',
  `image_url` varchar(255) DEFAULT NULL COMMENT 'Hình ảnh tổ hợp',
  `discount_price` decimal(15,2) DEFAULT NULL COMMENT 'Giá ưu đãi của tổ hợp',
  `original_price` decimal(15,2) DEFAULT NULL COMMENT 'Tổng giá gốc của các sản phẩm',
  `status` enum('active','inactive','pending') DEFAULT 'active' COMMENT 'Trạng thái tổ hợp',
  `created_by` int(11) NOT NULL COMMENT 'ID của admin/agency tạo tổ hợp',
  `creator_type` enum('admin','agency') NOT NULL COMMENT 'Loại người tạo (admin/agency)',
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `created_by` (`created_by`),
  KEY `creator_type` (`creator_type`),
  KEY `status` (`status`),
  CONSTRAINT `product_combinations_ibfk_1` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tạo bảng product_combination_items để lưu các sản phẩm trong tổ hợp
CREATE TABLE `product_combination_items` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `combination_id` int(11) NOT NULL COMMENT 'ID của tổ hợp',
  `product_id` int(11) NOT NULL COMMENT 'ID của sản phẩm',
  `variant_id` int(11) DEFAULT NULL COMMENT 'ID của biến thể (nếu có)',
  `quantity` int(11) NOT NULL DEFAULT 1 COMMENT 'Số lượng sản phẩm trong tổ hợp',
  `price_in_combination` decimal(15,2) DEFAULT NULL COMMENT 'Giá của sản phẩm trong tổ hợp (có thể khác giá gốc)',
  `created_at` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_combination_product` (`combination_id`, `product_id`, `variant_id`),
  KEY `combination_id` (`combination_id`),
  KEY `product_id` (`product_id`),
  KEY `variant_id` (`variant_id`),
  CONSTRAINT `product_combination_items_ibfk_1` FOREIGN KEY (`combination_id`) REFERENCES `product_combinations` (`id`) ON DELETE CASCADE,
  CONSTRAINT `product_combination_items_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
  CONSTRAINT `product_combination_items_ibfk_3` FOREIGN KEY (`variant_id`) REFERENCES `variants` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tạo bảng product_combination_categories để lưu danh mục của tổ hợp
CREATE TABLE `product_combination_categories` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `combination_id` int(11) NOT NULL COMMENT 'ID của tổ hợp',
  `category_name` varchar(100) NOT NULL COMMENT 'Tên danh mục',
  `created_at` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_combination_category` (`combination_id`, `category_name`),
  KEY `combination_id` (`combination_id`),
  CONSTRAINT `product_combination_categories_ibfk_1` FOREIGN KEY (`combination_id`) REFERENCES `product_combinations` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tạo trigger để tự động tính toán original_price khi thêm/sửa/xóa items
DELIMITER $$

CREATE TRIGGER `calculate_combination_original_price_insert` 
AFTER INSERT ON `product_combination_items`
FOR EACH ROW
BEGIN
    UPDATE product_combinations 
    SET original_price = (
        SELECT COALESCE(SUM(
            CASE 
                WHEN pci.price_in_combination IS NOT NULL THEN pci.price_in_combination * pci.quantity
                WHEN pv.price IS NOT NULL THEN pv.price * pci.quantity
                ELSE 0
            END
        ), 0)
        FROM product_combination_items pci
        LEFT JOIN product_variant pv ON pci.product_id = pv.product_id AND pci.variant_id = pv.variant_id
        WHERE pci.combination_id = NEW.combination_id
    )
    WHERE id = NEW.combination_id;
END$$

CREATE TRIGGER `calculate_combination_original_price_update` 
AFTER UPDATE ON `product_combination_items`
FOR EACH ROW
BEGIN
    UPDATE product_combinations 
    SET original_price = (
        SELECT COALESCE(SUM(
            CASE 
                WHEN pci.price_in_combination IS NOT NULL THEN pci.price_in_combination * pci.quantity
                WHEN pv.price IS NOT NULL THEN pv.price * pci.quantity
                ELSE 0
            END
        ), 0)
        FROM product_combination_items pci
        LEFT JOIN product_variant pv ON pci.product_id = pv.product_id AND pci.variant_id = pv.variant_id
        WHERE pci.combination_id = NEW.combination_id
    )
    WHERE id = NEW.combination_id;
END$$

CREATE TRIGGER `calculate_combination_original_price_delete` 
AFTER DELETE ON `product_combination_items`
FOR EACH ROW
BEGIN
    UPDATE product_combinations 
    SET original_price = (
        SELECT COALESCE(SUM(
            CASE 
                WHEN pci.price_in_combination IS NOT NULL THEN pci.price_in_combination * pci.quantity
                WHEN pv.price IS NOT NULL THEN pv.price * pci.quantity
                ELSE 0
            END
        ), 0)
        FROM product_combination_items pci
        LEFT JOIN product_variant pv ON pci.product_id = pv.product_id AND pci.variant_id = pv.variant_id
        WHERE pci.combination_id = OLD.combination_id
    )
    WHERE id = OLD.combination_id;
END$$

DELIMITER ;

-- Thêm dữ liệu mẫu
INSERT INTO `product_combinations` (`name`, `description`, `image_url`, `discount_price`, `original_price`, `status`, `created_by`, `creator_type`) VALUES
('Combo Áo Thun + Quần Jean', 'Tổ hợp áo thun và quần jean phong cách casual', 'combo_1.jpg', 250000.00, 300000.00, 'active', 6, 'admin'),
('Bộ Đồ Thể Thao Nam', 'Bộ đồ thể thao gồm áo và quần short', 'combo_2.jpg', 180000.00, 220000.00, 'active', 6, 'admin'),
('Combo Áo Khoác + Áo Thun', 'Tổ hợp áo khoác và áo thun mùa đông', 'combo_3.jpg', 400000.00, 500000.00, 'active', 9, 'agency');

-- Thêm categories cho các combo
INSERT INTO `product_combination_categories` (`combination_id`, `category_name`) VALUES
(1, 'T-Shirts'),
(1, 'Pants'),
(2, 'T-Shirts'),
(2, 'Pants'),
(3, 'T-Shirts'),
(3, 'Suits & Blazers');

-- Thêm items cho combo 1 (Áo Thun + Quần Jean)
INSERT INTO `product_combination_items` (`combination_id`, `product_id`, `variant_id`, `quantity`, `price_in_combination`) VALUES
(1, 3, 4, 1, 10000.00),  -- Áo thun
(1, 4, 6, 1, 200000.00); -- Áo đi biển (thay cho quần jean)

-- Thêm items cho combo 2 (Bộ Đồ Thể Thao)
INSERT INTO `product_combination_items` (`combination_id`, `product_id`, `variant_id`, `quantity`, `price_in_combination`) VALUES
(2, 3, 5, 1, 110000.00), -- Áo thun
(2, 4, 7, 1, 190000.00); -- Áo đi biển (thay cho quần short)

-- Thêm items cho combo 3 (Áo Khoác + Áo Thun)
INSERT INTO `product_combination_items` (`combination_id`, `product_id`, `variant_id`, `quantity`, `price_in_combination`) VALUES
(3, 6, 7, 1, 320000.00), -- Áo khoác
(3, 3, 4, 1, 10000.00);  -- Áo thun 