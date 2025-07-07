-- Thêm cột điều kiện cho bảng vouchers
ALTER TABLE vouchers 
ADD COLUMN min_quantity INT DEFAULT 1 COMMENT 'Số lượng sản phẩm tối thiểu để áp dụng',
ADD COLUMN min_total_amount DECIMAL(15,2) DEFAULT 0 COMMENT 'Tổng tiền tối thiểu để áp dụng';

-- Cập nhật dữ liệu ví dụ cho các voucher
UPDATE vouchers SET min_quantity = 1, min_total_amount = 60000 WHERE voucher_code = 'GIAM20K';
UPDATE vouchers SET min_quantity = 3, min_total_amount = 200000 WHERE voucher_code = 'GIAM30K';
UPDATE vouchers SET min_quantity = 1, min_total_amount = 0 WHERE voucher_code = 'WELCOME2024';
UPDATE vouchers SET min_quantity = 1, min_total_amount = 0 WHERE voucher_code = 'SUMMER50K';
UPDATE vouchers SET min_quantity = 1, min_total_amount = 0 WHERE voucher_code = 'NEWYEAR100K';
UPDATE vouchers SET min_quantity = 1, min_total_amount = 0 WHERE voucher_code = 'FLASH25K';
UPDATE vouchers SET min_quantity = 1, min_total_amount = 0 WHERE voucher_code = 'VIP200K';
UPDATE vouchers SET min_quantity = 1, min_total_amount = 0 WHERE voucher_code = 'EMMUONQUAMON';
UPDATE vouchers SET min_quantity = 1, min_total_amount = 0 WHERE voucher_code = 'TEST2025';
UPDATE vouchers SET min_quantity = 1, min_total_amount = 0 WHERE voucher_code = 'TEST2';
UPDATE vouchers SET min_quantity = 1, min_total_amount = 0 WHERE voucher_code = 'GIAM40K'; 