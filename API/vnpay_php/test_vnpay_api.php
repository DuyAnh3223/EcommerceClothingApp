<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    exit(0);
}

// Test database connection và VNPAY config
require_once("./config.php");

try {
    $pdo = getDBConnection();
    $config = debugVNPayConfig();
    
    if ($pdo) {
        echo json_encode([
            'success' => true,
            'message' => 'Database connection successful',
            'config' => $config,
            'test_data' => [
                'sample_order_id' => 1,
                'sample_amount' => 100000,
                'sample_user_id' => 4,
                'sample_create_date' => date('YmdHis'),
                'sample_expire_date' => date('YmdHis', strtotime('+15 minutes'))
            ]
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'Database connection failed',
            'config' => $config
        ]);
    }
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Error: ' . $e->getMessage(),
        'config' => debugVNPayConfig()
    ]);
}
?> 