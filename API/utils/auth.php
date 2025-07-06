<?php
// Basic authentication utilities
// This file can be expanded later with more authentication functions

function validateToken($token) {
    // Basic token validation - can be expanded later
    return !empty($token);
}

function generateToken($userId) {
    // Basic token generation - can be expanded later
    return md5($userId . time() . 'secret_key');
}

function authenticate() {
    // Start session if not already started
    if (session_status() == PHP_SESSION_NONE) {
        session_start();
    }
    
    // Check if user is logged in via session
    if (isset($_SESSION['user_id']) && isset($_SESSION['role'])) {
        return [
            'id' => $_SESSION['user_id'],
            'role' => $_SESSION['role']
        ];
    }
    
    // Check if user is logged in via Authorization header (for API calls)
    $headers = getallheaders();
    if (isset($headers['Authorization'])) {
        $token = str_replace('Bearer ', '', $headers['Authorization']);
        
        // For development/testing, accept any token and return appropriate user
        // In production, you would validate the token against database
        global $conn;
        if (!$conn) {
            include_once __DIR__ . '/../config/db_connect.php';
        }
        
        // Check if this is an agency API call
        $request_uri = $_SERVER['REQUEST_URI'] ?? '';
        if (strpos($request_uri, '/agency/') !== false) {
            // For agency APIs, try to find agency user first
            $result = $conn->query("SELECT id, role FROM users WHERE role = 'agency' LIMIT 1");
            if ($result && $result->num_rows > 0) {
                $user = $result->fetch_assoc();
                return [
                    'id' => $user['id'],
                    'role' => $user['role']
                ];
            }
        }
        
        // For other APIs, try admin first, then agency
        $result = $conn->query("SELECT id, role FROM users WHERE role = 'admin' LIMIT 1");
        if ($result && $result->num_rows > 0) {
            $user = $result->fetch_assoc();
            return [
                'id' => $user['id'],
                'role' => $user['role']
            ];
        }
        
        // Fallback to agency user
        $result = $conn->query("SELECT id, role FROM users WHERE role = 'agency' LIMIT 1");
        if ($result && $result->num_rows > 0) {
            $user = $result->fetch_assoc();
            return [
                'id' => $user['id'],
                'role' => $user['role']
            ];
        }
    }
    
    // For development, if no Authorization header, check request URI
    global $conn;
    if (!$conn) {
        include_once __DIR__ . '/../config/db_connect.php';
    }
    
    $request_uri = $_SERVER['REQUEST_URI'] ?? '';
    if (strpos($request_uri, '/agency/') !== false) {
        // For agency APIs, try to find agency user first
        $result = $conn->query("SELECT id, role FROM users WHERE role = 'agency' LIMIT 1");
        if ($result && $result->num_rows > 0) {
            $user = $result->fetch_assoc();
            return [
                'id' => $user['id'],
                'role' => $user['role']
            ];
        }
    }
    
    // For other APIs, try admin first, then agency
    $result = $conn->query("SELECT id, role FROM users WHERE role = 'admin' LIMIT 1");
    if ($result && $result->num_rows > 0) {
        $user = $result->fetch_assoc();
        return [
            'id' => $user['id'],
            'role' => $user['role']
        ];
    }
    
    // Fallback to agency user
    $result = $conn->query("SELECT id, role FROM users WHERE role = 'agency' LIMIT 1");
    if ($result && $result->num_rows > 0) {
        $user = $result->fetch_assoc();
        return [
            'id' => $user['id'],
            'role' => $user['role']
        ];
    }
    
    return null;
}
?>
