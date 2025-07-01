<?php
// Test script for add_attribute API
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "=== Test Add Attribute API ===\n\n";

// Set include path to current directory
set_include_path(__DIR__ . PATH_SEPARATOR . get_include_path());

// Simulate HTTP request with Authorization header
$_SERVER['REQUEST_METHOD'] = 'POST';
$_SERVER['HTTP_AUTHORIZATION'] = 'Bearer your_token_here';

// Simulate JSON input
$input_data = ['name' => 'Test Attribute ' . time()];
$json_input = json_encode($input_data);

// Override php://input for testing
$GLOBALS['HTTP_RAW_POST_DATA'] = $json_input;

echo "1. Testing with Authorization header...\n";
echo "   Authorization: Bearer your_token_here\n";
echo "   Input data: " . $json_input . "\n\n";

// Include the API file
ob_start();
include_once 'agency/variants_attributes/add_attribute.php';
$output = ob_get_clean();

echo "2. API Response:\n";
echo $output . "\n";

echo "=== Test completed ===\n";
?> 