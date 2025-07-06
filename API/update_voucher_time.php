<?php
header('Content-Type: application/json');
require_once 'config/db_connect.php';

// Set timezone to Vietnam
date_default_timezone_set('Asia/Ho_Chi_Minh');

try {
    // Update voucher GIAM20K to start from current time
    $currentTime = date('Y-m-d H:i:s');
    $endTime = date('Y-m-d H:i:s', strtotime('+1 month'));
    
    $updateQuery = "
        UPDATE vouchers 
        SET start_date = '$currentTime', 
            end_date = '$endTime',
            updated_at = NOW()
        WHERE voucher_code = 'GIAM20K'
    ";
    
    $result = mysqli_query($conn, $updateQuery);
    
    if ($result) {
        $response = [
            'success' => true,
            'message' => 'Voucher GIAM20K updated successfully',
            'new_start_date' => $currentTime,
            'new_end_date' => $endTime
        ];
    } else {
        $response = [
            'success' => false,
            'message' => 'Failed to update voucher',
            'error' => mysqli_error($conn)
        ];
    }
    
    echo json_encode($response, JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Error: ' . $e->getMessage()
    ], JSON_PRETTY_PRINT);
}

mysqli_close($conn);
?> 