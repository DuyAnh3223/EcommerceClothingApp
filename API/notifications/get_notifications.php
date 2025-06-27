<?php
require_once '../config/config.php';
require_once '../utils/response.php';

// Set CORS headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    sendResponse(false, 'Method not allowed', null, 405);
    exit();
}

try {
    $conn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);
    
    if ($conn->connect_error) {
        sendResponse(false, 'Connection failed: ' . $conn->connect_error, null, 500);
        exit();
    }
    
    $userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
    $page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
    $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 20;
    $type = isset($_GET['type']) ? $_GET['type'] : null;
    $isRead = isset($_GET['is_read']) ? $_GET['is_read'] : null;
    
    if (!$userId) {
        sendResponse(false, 'User ID is required', null, 400);
        exit();
    }
    
    // Calculate offset
    $offset = ($page - 1) * $limit;
    
    // Build query
    $sql = "SELECT id, title, content, type, is_read, created_at FROM notifications WHERE user_id = ?";
    $params = [$userId];
    $types = "i";
    
    // Add filters
    if ($type) {
        $sql .= " AND type = ?";
        $params[] = $type;
        $types .= "s";
    }
    
    if ($isRead !== null) {
        $sql .= " AND is_read = ?";
        $params[] = $isRead;
        $types .= "i";
    }
    
    // Add ordering and pagination
    $sql .= " ORDER BY created_at DESC LIMIT ? OFFSET ?";
    $params[] = $limit;
    $params[] = $offset;
    $types .= "ii";
    
    $stmt = $conn->prepare($sql);
    $stmt->bind_param($types, ...$params);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $notifications = [];
    while ($row = $result->fetch_assoc()) {
        $notifications[] = [
            'id' => (int)$row['id'],
            'title' => $row['title'],
            'content' => $row['content'],
            'type' => $row['type'],
            'is_read' => (bool)$row['is_read'],
            'created_at' => $row['created_at']
        ];
    }
    
    // Get total count for pagination
    $countSql = "SELECT COUNT(*) as total FROM notifications WHERE user_id = ?";
    if ($type) {
        $countSql .= " AND type = ?";
    }
    if ($isRead !== null) {
        $countSql .= " AND is_read = ?";
    }
    
    $countStmt = $conn->prepare($countSql);
    $countParams = [$userId];
    $countTypes = "i";
    
    if ($type) {
        $countParams[] = $type;
        $countTypes .= "s";
    }
    if ($isRead !== null) {
        $countParams[] = $isRead;
        $countTypes .= "i";
    }
    
    $countStmt->bind_param($countTypes, ...$countParams);
    $countStmt->execute();
    $countResult = $countStmt->get_result();
    $totalCount = $countResult->fetch_assoc()['total'];
    
    $stmt->close();
    $countStmt->close();
    $conn->close();
    
    sendResponse(true, 'Notifications retrieved successfully', [
        'notifications' => $notifications,
        'pagination' => [
            'current_page' => $page,
            'per_page' => $limit,
            'total' => (int)$totalCount,
            'total_pages' => ceil($totalCount / $limit)
        ]
    ]);
    
} catch (Exception $e) {
    sendResponse(false, 'Server error: ' . $e->getMessage(), null, 500);
}
?>
