<?php
header('Content-Type: application/json');

// Set timezone to Vietnam
date_default_timezone_set('Asia/Ho_Chi_Minh');

$now = new DateTime();
$voucherStartDate = new DateTime('2025-07-06 09:00:39');
$voucherEndDate = new DateTime('2025-08-05 09:00:39');

$response = [
    'current_time' => $now->format('Y-m-d H:i:s'),
    'voucher_start_date' => $voucherStartDate->format('Y-m-d H:i:s'),
    'voucher_end_date' => $voucherEndDate->format('Y-m-d H:i:s'),
    'is_before_start' => $now < $voucherStartDate,
    'is_after_end' => $now > $voucherEndDate,
    'is_valid' => $now >= $voucherStartDate && $now <= $voucherEndDate,
    'timezone' => date_default_timezone_get()
];

echo json_encode($response, JSON_PRETTY_PRINT);
?> 