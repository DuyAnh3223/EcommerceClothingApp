<?php
// Test the actual API endpoint
$productId = 12; // Agency product ID
$url = "http://127.0.0.1/EcommerceClothingApp/API/variants_attributes/get_variants.php?product_id=$productId";

echo "=== TESTING ACTUAL API ENDPOINT ===\n";
echo "URL: $url\n\n";

// Make the request
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HEADER, false);

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
    echo "Total variants: " . $data['total_variants'] . "\n";
    
    if (isset($data['variants']) && is_array($data['variants'])) {
        foreach ($data['variants'] as $index => $variant) {
            echo "\nVariant $index:\n";
            echo "- ID: " . $variant['variant_id'] . "\n";
            echo "- SKU: " . $variant['sku'] . "\n";
            echo "- Price: " . $variant['price'] . "\n";
            echo "- Stock: " . $variant['stock'] . "\n";
            echo "- Status: " . $variant['status'] . "\n";
            echo "- Image URL: " . ($variant['image_url'] ?: 'null') . "\n";
            echo "- Attribute values count: " . count($variant['attribute_values']) . "\n";
            
            if (!empty($variant['attribute_values'])) {
                foreach ($variant['attribute_values'] as $attr) {
                    echo "  * {$attr['attribute_name']}: {$attr['value']}\n";
                }
            }
        }
    }
    
    if (isset($data['product'])) {
        echo "\nProduct info:\n";
        echo "- ID: " . $data['product']['id'] . "\n";
        echo "- Name: " . $data['product']['name'] . "\n";
        echo "- Category: " . $data['product']['category'] . "\n";
        echo "- Status: " . $data['product']['status'] . "\n";
    }
}

echo "\n=== END TEST ===\n";
?> 