<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

require_once '../config/db_connect.php';
require_once '../utils/response.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(false, 'Method not allowed', null, 405);
}

try {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($input['product_id']) || !isset($input['action'])) {
        sendResponse(false, 'Product ID and action are required', null, 400);
    }
    
    $productId = intval($input['product_id']);
    $action = $input['action']; // 'approve' or 'reject'
    $reviewNotes = $input['review_notes'] ?? '';
    $adminId = $input['admin_id'] ?? null; // In real app, get from session/token
    
    if (!in_array($action, ['approve', 'reject'])) {
        sendResponse(false, 'Action must be either approve or reject', null, 400);
    }
    
    // Check if product exists and is pending approval
    $stmt = $conn->prepare("
        SELECT p.*, u.id as creator_id, u.username as creator_name
        FROM products p 
        JOIN users u ON p.created_by = u.id 
        WHERE p.id = ? AND p.is_agency_product = 1 AND p.status = 'pending'
    ");
    $stmt->bind_param("i", $productId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        sendResponse(false, 'Product not found or not pending approval', null, 404);
    }
    
    $product = $result->fetch_assoc();
    
    // Determine new status
    $newStatus = ($action === 'approve') ? 'approved' : 'rejected';
    
    // Update product status
    $stmt = $conn->prepare("
        UPDATE products 
        SET status = ?, updated_at = NOW() 
        WHERE id = ?
    ");
    $stmt->bind_param("si", $newStatus, $productId);
    
    if ($stmt->execute()) {
        // Update product approval record
        $stmt = $conn->prepare("
            UPDATE product_approvals 
            SET status = ?, reviewed_by = ?, review_notes = ?, reviewed_at = NOW() 
            WHERE product_id = ?
        ");
        $stmt->bind_param("sisi", $newStatus, $adminId, $reviewNotes, $productId);
        $stmt->execute();
        
        // Send notification to agency
        $title = ($action === 'approve') ? 'Sản phẩm đã được duyệt' : 'Sản phẩm bị từ chối';
        $content = ($action === 'approve') 
            ? "Sản phẩm '{$product['name']}' đã được admin duyệt và sẽ được hiển thị trên cửa hàng."
            : "Sản phẩm '{$product['name']}' đã bị admin từ chối. Lý do: $reviewNotes";
        
        $stmt = $conn->prepare("
            INSERT INTO notifications (user_id, title, content, type, created_at) 
            VALUES (?, ?, ?, 'product_approval', NOW())
        ");
        $stmt->bind_param("iss", $product['creator_id'], $title, $content);
        $stmt->execute();
        
        // If approved, set status to active for display
        if ($action === 'approve') {
            $stmt = $conn->prepare("
                UPDATE products 
                SET status = 'active', updated_at = NOW() 
                WHERE id = ?
            ");
            $stmt->bind_param("i", $productId);
            $stmt->execute();
        }
        
        sendResponse(true, "Product $action successfully", [
            'product_id' => $productId,
            'status' => $newStatus,
            'action' => $action,
            'review_notes' => $reviewNotes
        ], 200);
    } else {
        sendResponse(false, 'Failed to update product status', null, 500);
    }
    
} catch (Exception $e) {
    sendResponse(false, 'Server error: ' . $e->getMessage(), null, 500);
}

$conn->close();
?> 