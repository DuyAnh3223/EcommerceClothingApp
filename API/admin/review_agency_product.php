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
require_once '../utils/auth.php';

// Check if user is admin (temporarily disabled for testing)
$user = authenticate();
if (!$user) {
    // For testing, use a default admin user
    $user = ['id' => 6, 'role' => 'admin', 'username' => 'admin'];
}
// if ($user['role'] !== 'admin') {
//     sendResponse(false, 'Access denied. Admin role required.', null, 403);
//     exit();
// }

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
    $adminId = $user['id']; // Get admin ID from authenticated user
    
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
    $newStatus = ($action === 'approve') ? 'active' : 'rejected';
    
    // Update product status
    $stmt = $conn->prepare("
        UPDATE products 
        SET status = ?, updated_at = NOW() 
        WHERE id = ?
    ");
    $stmt->bind_param("si", $newStatus, $productId);
    
    if ($stmt->execute()) {
        // Create or update product approval record
        $approvalStatus = ($action === 'approve') ? 'approved' : 'rejected';
        $stmt = $conn->prepare("
            INSERT INTO product_approvals (product_id, status, reviewed_by, review_notes, reviewed_at, created_at) 
            VALUES (?, ?, ?, ?, NOW(), NOW()) 
            ON DUPLICATE KEY UPDATE 
            status = VALUES(status), 
            reviewed_by = VALUES(reviewed_by), 
            review_notes = VALUES(review_notes), 
            reviewed_at = VALUES(reviewed_at)
        ");
        $stmt->bind_param("isis", $productId, $approvalStatus, $adminId, $reviewNotes);
        $stmt->execute();
        
        // Get reviewer name
        $reviewerName = $user['username'] ?? 'Admin';
        
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
        
        sendResponse(true, "Product $action successfully", [
            'product_id' => $productId,
            'status' => $newStatus,
            'approval_status' => $approvalStatus,
            'action' => $action,
            'review_notes' => $reviewNotes,
            'reviewer_name' => $reviewerName,
            'reviewed_at' => date('Y-m-d H:i:s')
        ], 200);
    } else {
        sendResponse(false, 'Failed to update product status', null, 500);
    }
    
} catch (Exception $e) {
    sendResponse(false, 'Server error: ' . $e->getMessage(), null, 500);
}

$conn->close();
?> 