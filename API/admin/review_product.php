<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Access-Control-Allow-Headers,Content-Type,Access-Control-Allow-Methods,Authorization,X-Requested-With');

include_once '../config/db_connect.php';
include_once '../utils/response.php';
include_once '../utils/auth.php';

// // Check if user is admin
// $user = authenticate();
// if (!$user || $user['role'] !== 'admin') {
//     sendResponse(403, 'Access denied. Admin role required.');
//     exit();
// }

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(405, 'Method not allowed');
    exit();
}

try {
    $data = json_decode(file_get_contents("php://input"), true);
    
    // Validate required fields
    if (!isset($data['product_id']) || !isset($data['status'])) {
        sendResponse(400, 'Missing required fields: product_id and status');
        exit();
    }
    
    $product_id = intval($data['product_id']);
    $status = $data['status'];
    $review_notes = $data['review_notes'] ?? null;
    
    // Validate status
    if (!in_array($status, ['approved', 'rejected'])) {
        sendResponse(400, 'Invalid status. Must be "approved" or "rejected"');
        exit();
    }
    
    $conn->begin_transaction();
    
    // Check if product exists and is pending approval
    $stmt = $conn->prepare("
        SELECT p.*, u.username as agency_name 
        FROM products p 
        JOIN users u ON p.created_by = u.id 
        WHERE p.id = ? AND p.is_agency_product = 1 AND p.status = 'pending'
    ");
    $stmt->bind_param("i", $product_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        sendResponse(404, 'Product not found or not pending approval');
        exit();
    }
    
    $product = $result->fetch_assoc();
    
    // Update product status
    $new_status = ($status === 'approved') ? 'active' : 'rejected';
    $stmt = $conn->prepare("UPDATE products SET status = ? WHERE id = ?");
    $stmt->bind_param("si", $new_status, $product_id);
    $stmt->execute();
    
    // Update approval record
    $stmt = $conn->prepare("
        UPDATE product_approvals 
        SET status = ?, reviewed_by = ?, review_notes = ?, reviewed_at = NOW() 
        WHERE product_id = ?
    ");
    $stmt->bind_param("sisi", $status, $user['id'], $review_notes, $product_id);
    $stmt->execute();
    
    // Send notification to agency
    $notification_title = ($status === 'approved') ? 'Sản phẩm đã được duyệt' : 'Sản phẩm bị từ chối';
    $notification_content = ($status === 'approved') 
        ? "Sản phẩm '{$product['name']}' đã được duyệt và hiện đang bán trên app."
        : "Sản phẩm '{$product['name']}' đã bị từ chối. Lý do: " . ($review_notes ?? 'Không có lý do');
    
    $stmt = $conn->prepare("
        INSERT INTO notifications (user_id, title, content, type) 
        VALUES (?, ?, ?, 'product_approval')
    ");
    $stmt->bind_param("iss", $product['created_by'], $notification_title, $notification_content);
    $stmt->execute();
    
    $conn->commit();
    
    sendResponse(200, 'Product review completed successfully', [
        'product_id' => $product_id,
        'status' => $status,
        'message' => ($status === 'approved') ? 'Product is now active on the app' : 'Product has been rejected'
    ]);
    
} catch (Exception $e) {
    if ($conn->connect_errno === 0) {
        $conn->rollback();
    }
    sendResponse(500, 'Error reviewing product: ' . $e->getMessage());
}

$conn->close();
?> 