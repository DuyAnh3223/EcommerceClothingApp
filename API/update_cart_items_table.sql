-- Cập nhật bảng cart_items để hỗ trợ combo
ALTER TABLE `cart_items` 
ADD COLUMN `combination_id` int(11) DEFAULT NULL COMMENT 'ID của combo (nếu là combo)',
ADD COLUMN `combination_name` varchar(255) DEFAULT NULL COMMENT 'Tên combo',
ADD COLUMN `combination_image` varchar(255) DEFAULT NULL COMMENT 'Hình ảnh combo',
ADD COLUMN `combination_price` decimal(15,2) DEFAULT NULL COMMENT 'Giá combo',
ADD COLUMN `combination_items` text DEFAULT NULL COMMENT 'JSON chứa thông tin các sản phẩm trong combo',
ADD KEY `combination_id` (`combination_id`),
ADD CONSTRAINT `cart_items_ibfk_3` FOREIGN KEY (`combination_id`) REFERENCES `product_combinations` (`id`) ON DELETE CASCADE;

-- Cập nhật constraint để cho phép product_id và variant_id NULL khi là combo
ALTER TABLE `cart_items` 
DROP FOREIGN KEY `cart_items_ibfk_2`;

ALTER TABLE `cart_items` 
MODIFY `product_id` int(11) DEFAULT NULL,
MODIFY `variant_id` int(11) DEFAULT NULL;

ALTER TABLE `cart_items` 
ADD CONSTRAINT `cart_items_ibfk_2` FOREIGN KEY (`product_id`,`variant_id`) REFERENCES `product_variant` (`product_id`, `variant_id`) ON DELETE CASCADE; 