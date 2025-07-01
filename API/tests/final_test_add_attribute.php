<?php
// Final test for add_attribute API
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "=== Final Test Add Attribute API ===\n\n";

// Set include path
set_include_path(__DIR__ . PATH_SEPARATOR . get_include_path());

// Simulate HTTP request
$_SERVER['REQUEST_METHOD'] = 'POST';
$_SERVER['HTTP_AUTHORIZATION'] = 'Bearer your_token_here';

// Simulate JSON input
$input_data = ['name' => 'Final Test Attribute ' . time()];
$json_input = json_encode($input_data);

// Override php://input for testing
$GLOBALS['HTTP_RAW_POST_DATA'] = $json_input;

echo "1. Testing API with authentication...\n";
echo "   Method: POST\n";
echo "   Authorization: Bearer your_token_here\n";
echo "   Input: " . $json_input . "\n\n";

// Capture output
ob_start();
include_once 'agency/variants_attributes/add_attribute.php';
$output = ob_get_clean();

echo "2. API Response:\n";
echo $output . "\n";

// Parse JSON response
$response = json_decode($output, true);
if ($response) {
    echo "3. Parsed Response:\n";
    echo "   Success: " . ($response['success'] ? 'true' : 'false') . "\n";
    echo "   Message: " . ($response['message'] ?? 'N/A') . "\n";
    if (isset($response['data'])) {
        echo "   Data: " . print_r($response['data'], true) . "\n";
    }
} else {
    echo "3. Failed to parse JSON response\n";
}

echo "\n=== Test completed ===\n";
?> 