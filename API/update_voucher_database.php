<?php
require_once 'config/db_connect.php';

try {
    // Thêm các cột mới vào bảng vouchers
    $sql1 = "ALTER TABLE vouchers 
              ADD COLUMN min_quantity INT DEFAULT 1 COMMENT 'Số lượng sản phẩm tối thiểu để áp dụng',
              ADD COLUMN min_total_amount DECIMAL(15,2) DEFAULT 0 COMMENT 'Tổng tiền tối thiểu để áp dụng'";
    
    $conn->exec($sql1);
    echo "✅ Đã thêm cột min_quantity và min_total_amount vào bảng vouchers\n";
    
    // Cập nhật dữ liệu ví dụ cho các voucher
    $vouchers = [
        ['GIAM20K', 1, 60000],
        ['GIAM30K', 3, 200000],
        ['WELCOME2024', 1, 0],
        ['SUMMER50K', 1, 0],
        ['NEWYEAR100K', 1, 0],
        ['FLASH25K', 1, 0],
        ['VIP200K', 1, 0],
        ['EMMUONQUAMON', 1, 0],
        ['TEST2025', 1, 0],
        ['TEST2', 1, 0],
        ['GIAM40K', 1, 0]
    ];
    
    foreach ($vouchers as $voucher) {
        $sql2 = "UPDATE vouchers SET min_quantity = ?, min_total_amount = ? WHERE voucher_code = ?";
        $stmt = $conn->prepare($sql2);
        $stmt->execute([$voucher[1], $voucher[2], $voucher[0]]);
    }
    
    echo "✅ Đã cập nhật dữ liệu cho các voucher\n";
    echo "✅ Hoàn thành cập nhật cơ sở dữ liệu!\n";
    
} catch (PDOException $e) {
    echo "❌ Lỗi: " . $e->getMessage() . "\n";
}
?> 