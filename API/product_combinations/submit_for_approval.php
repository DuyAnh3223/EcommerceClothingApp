<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../config/db_connect.php';
require_once '../utils/response.php';
require_once '../utils/auth.php';

$user = authenticate();
if (!$user || $user['role'] !== 'agency') {
    sendResponse(false, 'Access denied. Agency role required.', null, 403);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(false, 'Method not allowed', null, 405);
}

try {
    $input = json_decode(file_get_contents('php://input'), true);
    if (!isset($input['combination_id'])) {
        sendResponse(false, 'Combination ID is required', null, 400);
    }
    $combinationId = intval($input['combination_id']);

    // Lấy thông tin tổ hợp
    $stmt = $conn->prepare("SELECT * FROM product_combinations WHERE id = ? AND creator_type = 'agency' AND created_by = ?");
    $stmt->bind_param("ii", $combinationId, $user['id']);
    $stmt->execute();
    $result = $stmt->get_result();
    if ($result->num_rows === 0) {
        sendResponse(false, 'Combination not found or not owned by agency', null, 404);
    }
    $combo = $result->fetch_assoc();

    // // Kiểm tra trạng thái tổ hợp
    // if (!in_array($combo['status'], ['inactive', 'rejected'])) {
    //     sendResponse(false, 'Combination can only be submitted when in inactive or rejected status', null, 400);
    // }

    // // Kiểm tra thông tin tổ hợp phải đầy đủ
    // if (empty($combo['name'])) {
    //     sendResponse(false, 'Combination must have a name', null, 400);
    // }
    // // Đếm số lượng category thực tế của tổ hợp
    // $stmt = $conn->prepare("SELECT COUNT(*) as cnt FROM product_combination_categories WHERE combination_id = ?");
    // $stmt->bind_param("i", $combinationId);
    // if (!$stmt->execute()) {
    //     sendResponse(false, 'Database error: ' . $stmt->error, null, 500);
    // }
    // $catResult = $stmt->get_result();
    // $catRow = $catResult ? $catResult->fetch_assoc() : null;
    // $catCount = $catRow && isset($catRow['cnt']) ? intval($catRow['cnt']) : 0;
    // if ($catCount < 1) {
    //     sendResponse(false, 'Combination must have at least one category', null, 400);
    // }
    // // Discount price phải hợp lệ
    // if (!isset($combo['discount_price']) || floatval($combo['discount_price']) <= 0) {
    //     sendResponse(false, 'Combination must have a valid discount price', null, 400);
    // }

    // // Kiểm tra tổ hợp có ít nhất 2 sản phẩm
    // $stmt = $conn->prepare("SELECT COUNT(*) as cnt FROM combination_items WHERE combination_id = ?");
    // $stmt->bind_param("i", $combinationId);
    // if (!$stmt->execute()) {
    //     sendResponse(false, 'Database error: ' . $stmt->error, null, 500);
    // }
    // $cntResult = $stmt->get_result();
    // $cntRow = $cntResult ? $cntResult->fetch_assoc() : null;
    // $cnt = $cntRow && isset($cntRow['cnt']) ? intval($cntRow['cnt']) : 0;
    // if ($cnt < 2) {
    //     sendResponse(false, 'Combination must have at least 2 products', null, 400);
    // }

    // (Optional) Kiểm tra từng sản phẩm trong tổ hợp nếu cần
    // $stmt = $conn->prepare("SELECT * FROM combination_items WHERE combination_id = ?");
    // $stmt->bind_param("i", $combinationId);
    // $stmt->execute();
    // $itemsResult = $stmt->get_result();
    // while ($item = $itemsResult->fetch_assoc()) {
    //     // Có thể kiểm tra từng sản phẩm trong tổ hợp ở đây
    // }

    $conn->begin_transaction();
    // Cập nhật trạng thái tổ hợp sang pending
    $stmt = $conn->prepare("UPDATE product_combinations SET status = 'pending', updated_at = NOW() WHERE id = ?");
    $stmt->bind_param("i", $combinationId);
    if ($stmt->execute()) {
        // Gửi thông báo cho admin
        $adminUsers = $conn->query("SELECT id FROM users WHERE role = 'admin'");
        while ($admin = $adminUsers->fetch_assoc()) {
            $stmt2 = $conn->prepare("INSERT INTO notifications (user_id, title, content, type, created_at) VALUES (?, ?, ?, 'combo_approval', NOW())");
            $title = 'Tổ hợp sản phẩm mới cần duyệt';
            $content = "Tổ hợp sản phẩm '{$combo['name']}' từ agency cần được duyệt.";
            $stmt2->bind_param("iss", $admin['id'], $title, $content);
            $stmt2->execute();
        }
        $conn->commit();
        sendResponse(true, 'Combination submitted for approval successfully', [
            'combination_id' => $combinationId,
            'status' => 'pending'
        ], 200);
    } else {
        $conn->rollback();
        sendResponse(false, 'Failed to submit combination for approval', null, 500);
    }
} catch (Exception $e) {
    if (isset($conn)) {
        $conn->rollback();
    }
    sendResponse(false, 'Server error: ' . $e->getMessage(), null, 500);
}
$conn->close(); 