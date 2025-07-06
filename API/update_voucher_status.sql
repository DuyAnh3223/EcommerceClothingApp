-- Cập nhật cấu trúc bảng vouchers để thêm trường status
ALTER TABLE `vouchers` 
ADD COLUMN `status` enum('active','inactive','expired') DEFAULT 'active' 
COMMENT 'Trạng thái voucher: active (có hiệu lực), inactive (hết hiệu lực), expired (hết hạn)';

-- Cập nhật trạng thái cho các voucher hiện tại
UPDATE `vouchers` SET `status` = 'active' WHERE `status` IS NULL;

-- Tạo trigger để tự động cập nhật trạng thái khi quantity = 0
DELIMITER $$
CREATE TRIGGER `update_voucher_status_on_quantity_zero` 
BEFORE UPDATE ON `vouchers` 
FOR EACH ROW 
BEGIN
    IF NEW.quantity = 0 AND OLD.quantity > 0 THEN
        SET NEW.status = 'inactive';
    END IF;
END$$
DELIMITER ;

-- Tạo trigger để tự động cập nhật trạng thái khi hết hạn
DELIMITER $$
CREATE TRIGGER `update_voucher_status_on_expiry` 
BEFORE UPDATE ON `vouchers` 
FOR EACH ROW 
BEGIN
    IF NEW.end_date < NOW() THEN
        SET NEW.status = 'expired';
    END IF;
END$$
DELIMITER ;

-- Tạo trigger để tự động cập nhật trạng thái khi insert
DELIMITER $$
CREATE TRIGGER `set_voucher_status_on_insert` 
BEFORE INSERT ON `vouchers` 
FOR EACH ROW 
BEGIN
    IF NEW.status IS NULL THEN
        SET NEW.status = 'active';
    END IF;
    
    IF NEW.end_date < NOW() THEN
        SET NEW.status = 'expired';
    END IF;
END$$
DELIMITER ; 