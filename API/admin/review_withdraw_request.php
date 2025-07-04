<?php

ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

require_once __DIR__ . '/../config/db_connect.php';
require_once __DIR__ . '/../utils/response.php';



header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header('Content-Type: application/json');

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['request_id'], $data['action'], $data['admin_id'])) {
    sendResponse(false, 'Missing required parameters');
    exit;
}

$request_id = $data['request_id'];
$action = $data['action'];
$admin_id = $data['admin_id'];
$admin_note = isset($data['admin_note']) ? $data['admin_note'] : null;

if (!in_array($action, ['approve', 'reject'])) {
    sendResponse(false, 'Invalid action');
    exit;
}

$status = $action === 'approve' ? 'approved' : 'rejected';

$sql = "UPDATE withdraw_requests SET status = ?, reviewed_by = ?, reviewed_at = NOW(), admin_note = ? WHERE id = ? AND status = 'pending'";
$stmt = $conn->prepare($sql);
$stmt->bind_param('sisi', $status, $admin_id, $admin_note, $request_id);

if ($stmt->execute() && $stmt->affected_rows > 0) {
    if ($status === 'approved') {
        // Lấy thông tin rút tiền và agency
        $amountSql = "SELECT amount, agency_id FROM withdraw_requests WHERE id = ?";
        $amountStmt = $conn->prepare($amountSql);
        $amountStmt->bind_param('i', $request_id);
        $amountStmt->execute();
        $amountResult = $amountStmt->get_result();
        if ($row = $amountResult->fetch_assoc()) {
            $amount = (float)$row['amount'];
            $agency_id = $row['agency_id'];
            // Cộng số tiền này vào personal_account_balance
            $updateBalanceSql = "UPDATE withdraw_agency SET personal_account_balance = personal_account_balance + ? WHERE agency_id = ?";
            $updateBalanceStmt = $conn->prepare($updateBalanceSql);
            $updateBalanceStmt->bind_param('di', $amount, $agency_id);
            $updateBalanceStmt->execute();
            $updateBalanceStmt->close();
            // Trừ số tiền này khỏi available_balance
            $updateAvailableSql = "UPDATE withdraw_agency SET available_balance = GREATEST(available_balance - ?, 0) WHERE agency_id = ?";
            $updateAvailableStmt = $conn->prepare($updateAvailableSql);
            $updateAvailableStmt->bind_param('di', $amount, $agency_id);
            $updateAvailableStmt->execute();
            $updateAvailableStmt->close();
            sendResponse(true, 'Withdraw request approved. Admin sẽ nhận được phí là: ' . $amount, ['platform_fee' => $amount]);
            exit;
        }
    }
    sendResponse(true, 'Withdraw request updated successfully');
} else {
    sendResponse(false, 'Update failed or request already reviewed');
} 