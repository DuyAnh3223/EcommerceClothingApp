<?php
require_once 'config/config.php';

try {
    $conn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);
    
    if ($conn->connect_error) {
        die(json_encode([
            'success' => false,
            'message' => 'Connection failed: ' . $conn->connect_error
        ]));
    }
    
    // First, update any users with 'other' gender to 'male'
    $updateUsers = "UPDATE users SET gender = 'male' WHERE gender = 'other'";
    $result = $conn->query($updateUsers);
    
    if ($result === false) {
        throw new Exception('Failed to update users: ' . $conn->error);
    }
    
    $affectedUsers = $conn->affected_rows;
    
    // Now modify the gender column to remove 'other' from enum
    $alterTable = "ALTER TABLE users MODIFY COLUMN gender ENUM('male', 'female') DEFAULT NULL";
    $result = $conn->query($alterTable);
    
    if ($result === false) {
        throw new Exception('Failed to alter table: ' . $conn->error);
    }
    
    echo json_encode([
        'success' => true,
        'message' => "Successfully updated gender enum. Updated $affectedUsers users from 'other' to 'male'.",
        'affected_users' => $affectedUsers
    ]);
    
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Error: ' . $e->getMessage()
    ]);
} finally {
    if (isset($conn)) {
        $conn->close();
    }
}
?> 