<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");
require_once '../config/db_connect.php';

$agency_id = isset($_GET['agency_id']) ? (int)$_GET['agency_id'] : 0;
if (!$agency_id) {
    echo json_encode([
        "success" => false,
        "message" => "Thiếu agency_id"
    ]);
    exit();
}

// Tổng tiền bán được (tất cả sản phẩm đã bán của agency, đơn đã xác nhận hoặc đã giao)
$sql = "
SELECT SUM(oi.price * oi.quantity) AS total_sales,
       SUM(oi.platform_fee * oi.quantity) AS platform_fee_total
FROM orders o
JOIN order_items oi ON o.id = oi.order_id
JOIN products p ON oi.product_id = p.id
WHERE p.created_by = ?
  AND p.is_agency_product = 1
  AND o.status IN ('confirmed', 'delivered')
";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $agency_id);
$stmt->execute();
$result = $stmt->get_result();
$row = $result->fetch_assoc();
$total_sales = (float)($row['total_sales'] ?? 0);
$platform_fee_total = (float)($row['platform_fee_total'] ?? 0);
$stmt->close();

// Số dư khả dụng (ở đây = tổng tiền bán được - tổng phí nền tảng - tổng đã rút)
$personal_account_balance = 0; // Nếu chưa có bảng withdraw
// Nếu có bảng withdraw, lấy tổng số tiền đã rút (tổng amount của agency_id)
if ($conn->query("SHOW TABLES LIKE 'withdraw_requests'")->num_rows > 0) {
    $sql2 = "SELECT SUM(amount) AS total_withdrawn FROM withdraw_requests WHERE agency_id = ? and status = 'approved'";
    $stmt2 = $conn->prepare($sql2);
    $stmt2->bind_param("i", $agency_id);
    $stmt2->execute();
    $result2 = $stmt2->get_result();
    $row2 = $result2->fetch_assoc();
    $personal_account_balance = (float)($row2['total_withdrawn'] ?? 0);
    $stmt2->close();
}

$available_balance = $total_sales - $platform_fee_total - $personal_account_balance;
if ($available_balance < 0) $available_balance = 0;

$conn->close();

echo json_encode([
    "success" => true,
    "total_sales" => $total_sales,
    "platform_fee_total" => $platform_fee_total,
    "available_balance" => $available_balance,
    "personal_account_balance" => $personal_account_balance
]); 










