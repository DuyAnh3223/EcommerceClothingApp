<?php
// Test script for agency products API
echo "Testing agency products API...\n";

// Simulate the API call
$_SERVER['REQUEST_METHOD'] = 'GET';
$_GET['status'] = 'all';
$_GET['page'] = '1';
$_GET['limit'] = '10';

// Include the API file
ob_start();
include 'agency/products/get_products.php';
$output = ob_get_clean();

echo "API Response:\n";
echo $output;

// Also test with specific status
echo "\n\nTesting with status=active:\n";
$_GET['status'] = 'active';
ob_start();
include 'agency/products/get_products.php';
$output = ob_get_clean();
echo $output;
?> 