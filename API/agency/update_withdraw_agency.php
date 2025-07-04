<?php
require_once '../config/db_connect.php';

$agency_id = isset($_GET['agency_id']) ? (int)$_GET['agency_id'] : 0;
if (!$agency_id) {
    echo "Thiếu agency_id";
    exit();
}

// 1. Tính tổng doanh thu và tổng phí (chỉ sản phẩm agency đã duyệt)
$sql = "
SELECT 
    SUM(oi.price * oi.quantity) AS total_sales,
    SUM(oi.platform_fee * oi.quantity) AS total_fee
FROM orders o
JOIN order_items oi ON o.id = oi.order_id
JOIN products p ON oi.product_id = p.id
WHERE p.created_by = ?
  AND p.is_agency_product = 1
  AND p.status IN ('approved', 'active')
  AND o.status IN ('confirmed', 'delivered')
";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $agency_id);
$stmt->execute();
$result = $stmt->get_result();
$row = $result->fetch_assoc();
$total_sales = (float)($row['total_sales'] ?? 0);
$total_fee = (float)($row['total_fee'] ?? 0);
$stmt->close();

// 2. Tính tổng đã rút
$sql2 = "SELECT SUM(amount) AS total_withdrawn FROM withdraw_requests WHERE agency_id = ? AND status = 'approved'";
$stmt2 = $conn->prepare($sql2);
$stmt2->bind_param("i", $agency_id);
$stmt2->execute();
$result2 = $stmt2->get_result();
$row2 = $result2->fetch_assoc();
$total_withdrawn = (float)($row2['total_withdrawn'] ?? 0);
$stmt2->close();

// 3. Tính số tiền còn lại có thể rút
$total_withdrawable = $total_sales - $total_fee - $total_withdrawn;
if ($total_withdrawable < 0) $total_withdrawable = 0;

// 4. Cập nhật hoặc chèn vào bảng withdraw_agency
$sql_check = "SELECT id FROM withdraw_agency WHERE agency_id = ?";
$stmt3 = $conn->prepare($sql_check);
$stmt3->bind_param("i", $agency_id);
$stmt3->execute();
$stmt3->store_result();

if ($stmt3->num_rows > 0) {
    // Đã có, update
    $sql_update = "UPDATE withdraw_agency SET total_sales = ?, total_fee = ?, total_withdrawable = ?, last_updated = NOW() WHERE agency_id = ?";
    $stmt4 = $conn->prepare($sql_update);
    $stmt4->bind_param("dddi", $total_sales, $total_fee, $total_withdrawable, $agency_id);
    $stmt4->execute();
    $stmt4->close();
} else {
    // Chưa có, insert
    $sql_insert = "INSERT INTO withdraw_agency (agency_id, total_sales, total_fee, total_withdrawable, last_updated) VALUES (?, ?, ?, ?, NOW())";
    $stmt4 = $conn->prepare($sql_insert);
    $stmt4->bind_param("iddd", $agency_id, $total_sales, $total_fee, $total_withdrawable);
    $stmt4->execute();
    $stmt4->close();
}
$stmt3->close();
$conn->close();

echo "Đã cập nhật withdraw_agency cho agency_id = $agency_id"; 