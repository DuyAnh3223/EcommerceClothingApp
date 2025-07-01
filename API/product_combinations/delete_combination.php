<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: DELETE');
header('Access-Control-Allow-Headers: Access-Control-Allow-Headers,Content-Type,Access-Control-Allow-Methods,Authorization,X-Requested-With');

include_once '../config/db_connect.php';
include_once '../utils/response.php';
include_once '../utils/auth.php';

if ($_SERVER['REQUEST_METHOD'] !== 'DELETE') {
    sendResponse(405, 'Method not allowed');
    exit();
}

try {
    $input = json_decode(file_get_contents('php://input'), true);
    $id = $input['id'] ?? null;
    if (!$id) {
        sendResponse(false, 'ID tổ hợp không được để trống');
        exit();
    }
    // Xóa tổ hợp (cascading sẽ xóa luôn items và categories)
    $stmt = $conn->prepare('DELETE FROM product_combinations WHERE id = ?');
    $stmt->bind_param('i', $id);
    $stmt->execute();
    if ($stmt->affected_rows > 0) {
        sendResponse(true, 'Xóa tổ hợp sản phẩm thành công');
    } else {
        sendResponse(false, 'Không tìm thấy tổ hợp để xóa');
    }
} catch (Exception $e) {
    sendResponse(false, 'Lỗi xóa tổ hợp sản phẩm: ' . $e->getMessage(), null, 500);
}

$conn->close();
?> 