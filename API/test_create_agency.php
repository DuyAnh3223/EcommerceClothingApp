<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Access-Control-Allow-Headers,Content-Type,Access-Control-Allow-Methods,Authorization,X-Requested-With');

include_once 'config/db_connect.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
    exit();
}

try {
    // Create agency account
    $username = 'agency1';
    $email = 'agency1@gmail.com';
    $phone = '0123456789';
    $password = md5('123456'); // Simple password for testing
    $role = 'agency';
    
    // Check if agency already exists
    $check_query = "SELECT id FROM users WHERE username = ? OR email = ?";
    $stmt = $conn->prepare($check_query);
    $stmt->bind_param("ss", $username, $email);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        echo json_encode([
            'success' => false,
            'message' => 'Agency account already exists'
        ]);
        exit();
    }
    
    // Insert new agency
    $insert_query = "INSERT INTO users (username, email, phone, password, role) VALUES (?, ?, ?, ?, ?)";
    $stmt = $conn->prepare($insert_query);
    $stmt->bind_param("sssss", $username, $email, $phone, $password, $role);
    
    if ($stmt->execute()) {
        $agency_id = $conn->insert_id;
        echo json_encode([
            'success' => true,
            'message' => 'Agency account created successfully',
            'data' => [
                'id' => $agency_id,
                'username' => $username,
                'email' => $email,
                'role' => $role
            ]
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'Failed to create agency account: ' . $conn->error
        ]);
    }
    
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Error: ' . $e->getMessage()
    ]);
}

$conn->close();
?> 