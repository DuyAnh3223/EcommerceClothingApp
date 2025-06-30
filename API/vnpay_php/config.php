<?php
// VNPAY Configuration
// Thông tin VNPAY thực tế

// Mã website tại VNPAY (Terminal ID)
$vnp_TmnCode = "F283H148";

// Chuỗi bí mật tạo checksum
$vnp_HashSecret = "2RHZSCS89LRN5YYJ543D05Z4MCASEAIP";

// URL thanh toán cho môi trường test
$vnp_Url = "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html";

// URL thanh toán cho môi trường production
// $vnp_Url = "https://pay.vnpay.vn/vpcpay.html";

// URL return sau khi thanh toán (API endpoint)
$vnp_Returnurl = "http://localhost/EcommerceClothingApp/API/vnpay_php/vnpay_return_api.php";

// URL IPN (Instant Payment Notification)
$vnp_IpnUrl = "http://localhost/EcommerceClothingApp/API/vnpay_php/vnpay_ipn.php";

// Cấu hình database
define('DB_HOST', '127.0.0.1');
define('DB_NAME', 'clothing_appstore');
define('DB_USER', 'root');
define('DB_PASS', '');

// Function để kết nối database sử dụng PDO
function getDBConnection() {
    try {
        $pdo = new PDO(
            "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4",
            DB_USER,
            DB_PASS,
            [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false,
            ]
        );
        return $pdo;
    } catch (PDOException $e) {
        error_log("Database connection failed: " . $e->getMessage());
        return null;
    }
}

// Debug function để kiểm tra cấu hình
function debugVNPayConfig() {
    global $vnp_TmnCode, $vnp_HashSecret, $vnp_Url, $vnp_Returnurl;
    return [
        'tmn_code' => $vnp_TmnCode,
        'url' => $vnp_Url,
        'return_url' => $vnp_Returnurl,
        'hash_secret_length' => strlen($vnp_HashSecret),
        'timezone' => date_default_timezone_get(),
        'current_time' => date('Y-m-d H:i:s'),
        'current_time_vnpay_format' => date('YmdHis')
    ];
}
?> 