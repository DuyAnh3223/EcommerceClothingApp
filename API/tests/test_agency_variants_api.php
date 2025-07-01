<?php
// Test the agency variants API endpoint
$productId = 12; // Agency product ID
$url = "http://127.0.0.1/EcommerceClothingApp/API/agency/variants_attributes/get_variants.php?product_id=$productId";

echo "=== TESTING AGENCY VARIANTS API ENDPOINT ===\n";
echo "URL: $url\n\n";

// Make the request
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HEADER, false);
// Add Authorization header for agency user
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Authorization: Bearer agency_token_placeholder',
    'Content-Type: application/json'
]);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "HTTP Code: $httpCode\n";
echo "Response:\n";
echo $response . "\n";

// Parse JSON response
$data = json_decode($response, true);
if ($data) {
    echo "\n=== PARSED RESPONSE ===\n";
    echo "Success: " . ($data['success'] ? 'true' : 'false') . "\n";
    echo "Message: " . $data['message'] . "\n";
    
    if (isset($data['data']) && is_array($data['data'])) {
        echo "Data structure:\n";
        print_r($data['data']);
        
        if (isset($data['data']['variants']) && is_array($data['data']['variants'])) {
            echo "\nVariants count: " . count($data['data']['variants']) . "\n";
            
            foreach ($data['data']['variants'] as $index => $variant) {
                echo "\nVariant $index:\n";
                echo "- Variant ID: " . $variant['variant_id'] . "\n";
                echo "- SKU: " . $variant['sku'] . "\n";
                echo "- Price: " . $variant['price'] . "\n";
                echo "- Stock: " . $variant['stock'] . "\n";
                echo "- Status: " . $variant['variant_status'] . "\n";
                echo "- Image URL: " . ($variant['image_url'] ?: 'null') . "\n";
                echo "- Product ID: " . $variant['product_id'] . "\n";
                echo "- Product Name: " . $variant['product_name'] . "\n";
                echo "- Attributes count: " . count($variant['attributes']) . "\n";
                
                if (!empty($variant['attributes'])) {
                    foreach ($variant['attributes'] as $attr) {
                        echo "  * {$attr['attribute_name']}: {$attr['value']} (ID: {$attr['value_id']})\n";
                    }
                }
            }
        }
    }
} else {
    echo "\nFailed to parse JSON response\n";
}

echo "\n=== END TEST ===\n";
?> 