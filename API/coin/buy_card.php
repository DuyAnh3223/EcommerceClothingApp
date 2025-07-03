<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

require_once '../config/db_connect.php';

function randomString($length = 12) {
    $characters = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    $charactersLength = strlen($characters);
    $randomString = '';
    for ($i = 0; $i < $length; $i++) {
        $randomString .= $characters[rand(0, $charactersLength - 1)];
    }
    return $randomString;
}

$user_id = $_POST['user_id'] ?? null;
$promotion_id = $_POST['promotion_id'] ?? null;

if (!$user_id || !$promotion_id) {
    echo json_encode(["success" => false, "message" => "Thiếu user_id hoặc promotion_id!"]);
    exit;
}

// Lấy thông tin promotion để lấy giá
$sqlPromo = "SELECT * FROM promotion WHERE id = ? LIMIT 1";
$stmtPromo = $conn->prepare($sqlPromo);
$stmtPromo->bind_param("i", $promotion_id);
$stmtPromo->execute();
$promoResult = $stmtPromo->get_result();
$promo = $promoResult->fetch_assoc();
$stmtPromo->close();

if (!$promo) {
    echo json_encode(["success" => false, "message" => "Không tìm thấy loại ưu đãi!"]);
    exit;
}
$price = $promo['original_price'];
$crypto_coin = $promo['converted_price'];

// Lấy số dư tiền mặt
$sqlCash = "SELECT balance FROM user_cash_wallet WHERE user_id = ?";
$stmtCash = $conn->prepare($sqlCash);
$stmtCash->bind_param("i", $user_id);
$stmtCash->execute();
$stmtCash->bind_result($cash_balance);
$stmtCash->fetch();
$stmtCash->close();

if ($cash_balance < $price) {
    echo json_encode(["success" => false, "message" => "Không đủ tiền mặt để mua thẻ!"]);
    exit;
}

// Trừ tiền mặt
$sqlUpdateCash = "UPDATE user_cash_wallet SET balance = balance - ? WHERE user_id = ?";
$stmtUpdateCash = $conn->prepare($sqlUpdateCash);
$stmtUpdateCash->bind_param("di", $price, $user_id);
$stmtUpdateCash->execute();
$stmtUpdateCash->close();

// Lấy tất cả thẻ chưa dùng thuộc loại này
$sql = "SELECT * FROM card WHERE promotion_id = ? AND status = 'unused'";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $promotion_id);
$stmt->execute();
$result = $stmt->get_result();
$cards = [];
while ($row = $result->fetch_assoc()) {
    $cards[] = [
        "id" => $row['id'],
        "serial_number" => $row['serial_number'],
        "card_code" => $row['card_code'],
        "price" => $row['price'],
        "crypto_coin" => $row['crypto_coin'],
        "status" => $row['status']
    ];
}
$stmt->close();

// Nếu chưa có thẻ nào, tự động tạo 5 thẻ mới
if (count($cards) == 0) {
    $created = 0;
    $tries = 0;
    $quantity = 5;
    while ($created < $quantity && $tries < $quantity * 10) {
        $serial = randomString(12);
        $code = randomString(10);
        // Kiểm tra trùng serial_number hoặc card_code
        $check = $conn->prepare("SELECT id FROM card WHERE serial_number = ? OR card_code = ? LIMIT 1");
        $check->bind_param("ss", $serial, $code);
        $check->execute();
        $check->store_result();
        if ($check->num_rows == 0) {
            $sqlInsert = "INSERT INTO card (serial_number, card_code, promotion_id, price, crypto_coin, status) VALUES (?, ?, ?, ?, ?, 'unused')";
            $stmtInsert = $conn->prepare($sqlInsert);
            $stmtInsert->bind_param("ssidd", $serial, $code, $promotion_id, $price, $crypto_coin);
            if ($stmtInsert->execute()) {
                $created++;
            }
            $stmtInsert->close();
        }
        $check->close();
        $tries++;
    }
    // Lấy lại danh sách thẻ vừa tạo
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $promotion_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $cards = [];
    while ($row = $result->fetch_assoc()) {
        $cards[] = [
            "id" => $row['id'],
            "serial_number" => $row['serial_number'],
            "card_code" => $row['card_code'],
            "price" => $row['price'],
            "crypto_coin" => $row['crypto_coin'],
            "status" => $row['status']
        ];
    }
    $stmt->close();
}

if (count($cards) > 0) {
    echo json_encode([
        "success" => true,
        "cards" => $cards
    ]);
} else {
    echo json_encode(["success" => false, "message" => "Hết thẻ loại này! Không thể tạo thêm thẻ mới!"]);
}
?>