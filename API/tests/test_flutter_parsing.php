<?php
// Test Flutter parsing logic with the actual API response
echo "=== TESTING FLUTTER PARSING LOGIC ===\n";

// Simulate the API response that we know works
$apiResponse = [
    "success" => true,
    "message" => "Variants retrieved successfully",
    "data" => [
        "variants" => [
            [
                "variant_id" => 13,
                "sku" => "AGENCY-12-686336d219c25",
                "price" => 300000,
                "stock" => 30,
                "image_url" => null,
                "variant_status" => "active",
                "product_id" => 12,
                "product_name" => "A",
                "product_status" => "",
                "attributes" => [
                    [
                        "attribute_id" => 3,
                        "attribute_name" => "brand",
                        "value_id" => 15,
                        "value" => "Adidas"
                    ],
                    [
                        "attribute_id" => 1,
                        "attribute_name" => "color",
                        "value_id" => 17,
                        "value" => "while"
                    ],
                    [
                        "attribute_id" => 2,
                        "attribute_name" => "size",
                        "value_id" => 12,
                        "value" => "X"
                    ]
                ]
            ]
        ],
        "total" => 1
    ]
];

echo "API Response:\n";
echo json_encode($apiResponse, JSON_PRETTY_PRINT) . "\n\n";

// Simulate Flutter parsing logic
echo "=== FLUTTER PARSING SIMULATION ===\n";

// Step 1: Check if success
if ($apiResponse['success']) {
    echo "✅ Success: true\n";
    
    $data = $apiResponse['data'];
    echo "✅ Data structure exists\n";
    
    // Step 2: Check variants
    if (isset($data['variants']) && is_array($data['variants'])) {
        echo "✅ Variants is array with " . count($data['variants']) . " items\n";
        
        foreach ($data['variants'] as $index => $variant) {
            echo "\n--- Processing Variant $index ---\n";
            
            // Simulate ProductVariant.fromJson
            $variantId = isset($variant['variant_id']) ? $variant['variant_id'] : (isset($variant['id']) ? $variant['id'] : 0);
            $sku = $variant['sku'] ?? '';
            $price = floatval($variant['price'] ?? 0);
            $stock = intval($variant['stock'] ?? 0);
            $imageUrl = $variant['image_url'];
            $status = $variant['variant_status'] ?? $variant['status'] ?? 'active';
            $productId = intval($variant['product_id'] ?? 0);
            
            echo "✅ Variant ID: $variantId\n";
            echo "✅ SKU: $sku\n";
            echo "✅ Price: $price\n";
            echo "✅ Stock: $stock\n";
            echo "✅ Status: $status\n";
            echo "✅ Product ID: $productId\n";
            
            // Simulate AttributeValue.fromJson
            if (isset($variant['attributes']) && is_array($variant['attributes'])) {
                echo "✅ Attributes count: " . count($variant['attributes']) . "\n";
                
                foreach ($variant['attributes'] as $attrIndex => $attr) {
                    $attrId = isset($attr['value_id']) ? $attr['value_id'] : (isset($attr['id']) ? $attr['id'] : 0);
                    $value = $attr['value'] ?? '';
                    $attrAttributeId = intval($attr['attribute_id'] ?? 0);
                    $attrName = $attr['attribute_name'] ?? '';
                    
                    echo "  ✅ Attribute $attrIndex: $attrName = $value (ID: $attrId)\n";
                }
            } else {
                echo "❌ No attributes found\n";
            }
        }
    } else {
        echo "❌ Variants is not an array or doesn't exist\n";
    }
} else {
    echo "❌ API call failed\n";
}

echo "\n=== END FLUTTER PARSING TEST ===\n";
?> 