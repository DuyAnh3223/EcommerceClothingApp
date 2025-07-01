<?php
// Test file for agency get_products API
header('Content-Type: application/json');

// Simulate agency user login
session_start();

// Lấy user ID của agency từ database
require_once 'config/db_connect.php';
$stmt = $conn->prepare("SELECT id FROM users WHERE role = 'agency' LIMIT 1");
$stmt->execute();
$result = $stmt->get_result();
$agency_user = $result->fetch_assoc();

if (!$agency_user) {
    echo json_encode([
        'error' => 'No agency user found. Please run test_create_agency_user.php first.',
        'message' => 'Chạy file test_create_agency_user.php để tạo user agency trước'
    ]);
    exit;
}

$_SESSION['user_id'] = $agency_user['id'];
$_SESSION['role'] = 'agency';

echo "Using agency user ID: " . $agency_user['id'] . "\n";

// Test the API
$url = 'http://127.0.0.1/EcommerceClothingApp/API/agency/products/get_products.php';
$headers = [
    'Content-Type: application/json',
    'Authorization: Bearer test_token' // You might need to adjust this based on your auth implementation
];

$context = stream_context_create([
    'http' => [
        'method' => 'GET',
        'header' => implode("\r\n", $headers),
    ]
]);

$response = file_get_contents($url, false, $context);

if ($response === false) {
    echo json_encode([
        'error' => 'Failed to connect to API',
        'url' => $url
    ]);
} else {
    echo $response;
}

$conn->close();
?> 