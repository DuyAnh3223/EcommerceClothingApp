<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    exit(0);
}

error_reporting(E_ALL & ~E_NOTICE & ~E_DEPRECATED);
date_default_timezone_set('Asia/Ho_Chi_Minh');

require_once("./config.php");

// Log all incoming data for debugging
error_log("=== VNPAY RETURN DEBUG START ===");
error_log("Request Method: " . $_SERVER['REQUEST_METHOD']);
error_log("GET Parameters: " . print_r($_GET, true));
error_log("POST Parameters: " . print_r($_POST, true));
error_log("Raw Input: " . file_get_contents('php://input'));

// Handle both GET and POST requests
$input = array_merge($_GET, $_POST);

if (empty($input)) {
    error_log("No input data received");
    echo json_encode([
        'success' => false,
        'error' => 'No payment data received',
        'debug' => [
            'method' => $_SERVER['REQUEST_METHOD'],
            'timestamp' => date('Y-m-d H:i:s'),
            'timezone' => date_default_timezone_get()
        ]
    ]);
    exit;
}

// Extract VNPAY response parameters
$vnp_ResponseCode = $input['vnp_ResponseCode'] ?? '';
$vnp_OrderInfo = $input['vnp_OrderInfo'] ?? '';
$vnp_TxnRef = $input['vnp_TxnRef'] ?? '';
$vnp_Amount = $input['vnp_Amount'] ?? '';
$vnp_SecureHash = $input['vnp_SecureHash'] ?? '';
$vnp_TransactionNo = $input['vnp_TransactionNo'] ?? '';
$vnp_BankCode = $input['vnp_BankCode'] ?? '';
$vnp_PayDate = $input['vnp_PayDate'] ?? '';

error_log("VNPAY Response Code: $vnp_ResponseCode");
error_log("VNPAY Order Info: $vnp_OrderInfo");
error_log("VNPAY Txn Ref: $vnp_TxnRef");
error_log("VNPAY Amount: $vnp_Amount");
error_log("VNPAY Transaction No: $vnp_TransactionNo");
error_log("VNPAY Bank Code: $vnp_BankCode");
error_log("VNPAY Pay Date: $vnp_PayDate");

// Verify secure hash
$inputData = array();
foreach ($input as $key => $value) {
    if (substr($key, 0, 4) == "vnp_") {
        $inputData[$key] = $value;
    }
}

// Remove vnp_SecureHash from input data
unset($inputData['vnp_SecureHash']);

// Sort input data
ksort($inputData);

// Create hash data
$hashData = "";
$i = 0;
foreach ($inputData as $key => $value) {
    if ($i == 1) {
        $hashData .= '&' . urlencode($key) . "=" . urlencode($value);
    } else {
        $hashData .= urlencode($key) . "=" . urlencode($value);
        $i = 1;
    }
}

// Calculate secure hash
$secureHash = hash_hmac('sha512', $hashData, $vnp_HashSecret);

error_log("Calculated Hash: $secureHash");
error_log("Received Hash: $vnp_SecureHash");
error_log("Hash Match: " . ($secureHash === $vnp_SecureHash ? 'YES' : 'NO'));

// Verify hash
if ($secureHash !== $vnp_SecureHash) {
    error_log("Hash verification failed");
    echo json_encode([
        'success' => false,
        'error' => 'Invalid secure hash',
        'response_code' => $vnp_ResponseCode,
        'debug' => [
            'calculated_hash' => $secureHash,
            'received_hash' => $vnp_SecureHash,
            'hash_data' => $hashData
        ]
    ]);
    exit;
}

// Process payment result
$paymentStatus = 'failed';
$message = 'Payment failed';

switch ($vnp_ResponseCode) {
    case '00':
        $paymentStatus = 'success';
        $message = 'Payment successful';
        break;
    case '24':
        $paymentStatus = 'cancelled';
        $message = 'Customer cancelled the payment';
        break;
    case '07':
        $paymentStatus = 'failed';
        $message = 'Invalid amount';
        break;
    case '09':
        $paymentStatus = 'failed';
        $message = 'Invalid order info';
        break;
    case '11':
        $paymentStatus = 'failed';
        $message = 'Invalid order type';
        break;
    case '12':
        $paymentStatus = 'failed';
        $message = 'Invalid currency';
        break;
    case '13':
        $paymentStatus = 'failed';
        $message = 'Invalid IP address';
        break;
    case '51':
        $paymentStatus = 'failed';
        $message = 'Insufficient balance';
        break;
    case '65':
        $paymentStatus = 'failed';
        $message = 'Exceed daily limit';
        break;
    case '75':
        $paymentStatus = 'failed';
        $message = 'Bank maintenance';
        break;
    case '79':
        $paymentStatus = 'failed';
        $message = 'Invalid customer info';
        break;
    case '99':
        $paymentStatus = 'failed';
        $message = 'Unknown error';
        break;
    default:
        $paymentStatus = 'failed';
        $message = "Unknown response code: $vnp_ResponseCode";
        break;
}

// Try to update database if payment was successful
$dbUpdated = false;
if ($paymentStatus === 'success') {
    try {
        $pdo = getDBConnection();
        if ($pdo) {
            // Update payment status
            $stmt = $pdo->prepare("
                UPDATE payments 
                SET status = ?, transaction_code = ?, paid_at = NOW() 
                WHERE order_id = ? AND payment_method = 'VNPAY'
            ");
            $stmt->execute([$paymentStatus, $vnp_TransactionNo, $vnp_TxnRef]);
            
            // Update order status if payment successful
            if ($stmt->rowCount() > 0) {
                $stmt = $pdo->prepare("
                    UPDATE orders 
                    SET status = 'confirmed', updated_at = NOW() 
                    WHERE id = ?
                ");
                $stmt->execute([$vnp_TxnRef]);
                $dbUpdated = true;
            }
        }
    } catch (Exception $e) {
        error_log("Database update error: " . $e->getMessage());
    }
}

// Prepare response
$response = [
    'success' => $paymentStatus === 'success',
    'payment_status' => $paymentStatus,
    'message' => $message,
    'response_code' => $vnp_ResponseCode,
    'order_id' => $vnp_TxnRef,
    'amount' => $vnp_Amount / 100, // Convert back from VNPAY format
    'transaction_no' => $vnp_TransactionNo,
    'bank_code' => $vnp_BankCode,
    'pay_date' => $vnp_PayDate,
    'order_info' => $vnp_OrderInfo,
    'debug' => [
        'hash_verified' => true,
        'database_updated' => $dbUpdated,
        'timestamp' => date('Y-m-d H:i:s'),
        'timezone' => date_default_timezone_get()
    ]
];

error_log("Final Response: " . json_encode($response));
error_log("=== VNPAY RETURN DEBUG END ===");

echo json_encode($response);
?>
