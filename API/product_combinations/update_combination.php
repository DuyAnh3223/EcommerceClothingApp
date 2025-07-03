<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: PUT');
header('Access-Control-Allow-Headers: Access-Control-Allow-Headers,Content-Type,Access-Control-Allow-Methods,Authorization,X-Requested-With');

include_once '../config/db_connect.php';
include_once '../utils/response.php';
include_once '../utils/auth.php';

if ($_SERVER['REQUEST_METHOD'] !== 'PUT') {
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

    // Lấy thông tin cũ
    $stmt = $conn->prepare('SELECT * FROM product_combinations WHERE id = ?');
    $stmt->bind_param('i', $id);
    $stmt->execute();
    $old = $stmt->get_result()->fetch_assoc();
    if (!$old) {
        sendResponse(false, 'Tổ hợp không tồn tại');
        exit();
    }

    // Nếu chỉ truyền status (duyệt/từ chối), chỉ update status
    if (isset($input['status']) && count($input) == 2 && isset($input['id'])) {
        $stmt = $conn->prepare('UPDATE product_combinations SET status = ? WHERE id = ?');
        $stmt->bind_param('si', $input['status'], $id);
        $stmt->execute();
        $msg = $input['status'] === 'active' ? 'Duyệt tổ hợp thành công' : ($input['status'] === 'rejected' ? 'Từ chối tổ hợp thành công' : 'Cập nhật trạng thái thành công');
        sendResponse(true, $msg);
        exit();
    }

    // Update thông tin chính (chỉ update trường nào truyền lên, giữ nguyên trường cũ nếu không truyền)
    $name = array_key_exists('name', $input) ? $input['name'] : $old['name'];
    $description = array_key_exists('description', $input) ? $input['description'] : $old['description'];
    $image_url = array_key_exists('image_url', $input) ? $input['image_url'] : $old['image_url'];
    $discount_price = array_key_exists('discount_price', $input) ? $input['discount_price'] : $old['discount_price'];
    $status = array_key_exists('status', $input) ? $input['status'] : $old['status'];

    $stmt = $conn->prepare('UPDATE product_combinations SET name = ?, description = ?, image_url = ?, discount_price = ?, status = ? WHERE id = ?');
    $stmt->bind_param('sssssi', $name, $description, $image_url, $discount_price, $status, $id);
    $stmt->execute();

    // Update categories nếu có
    if (isset($input['categories']) && is_array($input['categories'])) {
        // Xóa cũ
        $stmt = $conn->prepare('DELETE FROM product_combination_categories WHERE combination_id = ?');
        $stmt->bind_param('i', $id);
        $stmt->execute();
        // Thêm mới
        $cat_stmt = $conn->prepare('INSERT INTO product_combination_categories (combination_id, category_name) VALUES (?, ?)');
        foreach ($input['categories'] as $category) {
            $cat_stmt->bind_param('is', $id, $category);
            $cat_stmt->execute();
        }
    }

    // Update items nếu có
    if (isset($input['items']) && is_array($input['items'])) {
        // Xóa cũ
        $stmt = $conn->prepare('DELETE FROM product_combination_items WHERE combination_id = ?');
        $stmt->bind_param('i', $id);
        $stmt->execute();
        // Thêm mới
        $item_stmt = $conn->prepare('INSERT INTO product_combination_items (combination_id, product_id, variant_id, quantity, price_in_combination) VALUES (?, ?, ?, ?, ?)');
        foreach ($input['items'] as $item) {
            $item_stmt->bind_param(
                'iiidd',
                $id,
                $item['product_id'],
                $item['variant_id'] ?? null,
                $item['quantity'] ?? 1,
                $item['price_in_combination'] ?? null
            );
            $item_stmt->execute();
        }
    }

    sendResponse(true, 'Cập nhật tổ hợp sản phẩm thành công');
} catch (Exception $e) {
    sendResponse(false, 'Lỗi cập nhật tổ hợp sản phẩm: ' . $e->getMessage(), null, 500);
}

$conn->close();
?> 