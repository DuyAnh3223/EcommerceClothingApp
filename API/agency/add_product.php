<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Access-Control-Allow-Headers,Content-Type,Access-Control-Allow-Methods,Authorization,X-Requested-With');

include_once '../config/db_connect.php';
include_once '../utils/response.php';
include_once '../utils/auth.php';
include_once '../utils/validate.php';

// Check if user is agency
$user = authenticate();
if (!$user || $user['role'] !== 'agency') {
    sendResponse(403, 'Access denied. Agency role required.');
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(405, 'Method not allowed');
    exit();
}

try {
    $data = json_decode(file_get_contents("php://input"), true);
    
    // Validate required fields
    $required_fields = ['name', 'description', 'category', 'gender_target', 'variants'];
    foreach ($required_fields as $field) {
        if (!isset($data[$field]) || empty($data[$field])) {
            sendResponse(400, "Missing required field: $field");
            exit();
        }
    }
    
    // Validate variants structure
    if (!is_array($data['variants']) || empty($data['variants'])) {
        sendResponse(400, 'At least one variant is required');
        exit();
    }
    
    $conn->begin_transaction();
    
    // Insert product
    $stmt = $conn->prepare("
        INSERT INTO products (name, description, category, gender_target, main_image, created_by, is_agency_product, status, platform_fee_rate) 
        VALUES (?, ?, ?, ?, ?, ?, 1, 'pending', 20.00)
    ");
    $stmt->bind_param("sssssi", 
        $data['name'], 
        $data['description'], 
        $data['category'], 
        $data['gender_target'], 
        $data['main_image'] ?? null,
        $user['id']
    );
    $stmt->execute();
    $product_id = $conn->insert_id;
    
    // Create product approval record
    $stmt = $conn->prepare("
        INSERT INTO product_approvals (product_id, status) 
        VALUES (?, 'pending')
    ");
    $stmt->bind_param("i", $product_id);
    $stmt->execute();
    
    // Process variants
    foreach ($data['variants'] as $variant_data) {
        if (!isset($variant_data['price']) || !isset($variant_data['stock']) || !isset($variant_data['attributes'])) {
            throw new Exception('Invalid variant data');
        }
        
        // Generate SKU
        $sku = 'AGENCY-' . $product_id . '-' . uniqid();
        
        // Insert variant
        $stmt = $conn->prepare("INSERT INTO variants (sku) VALUES (?)");
        $stmt->bind_param("s", $sku);
        $stmt->execute();
        $variant_id = $conn->insert_id;
        
        // Insert product variant
        $stmt = $conn->prepare("
            INSERT INTO product_variant (product_id, variant_id, price, stock, image_url) 
            VALUES (?, ?, ?, ?, ?)
        ");
        $stmt->bind_param("iidss", 
            $product_id, 
            $variant_id, 
            $variant_data['price'], 
            $variant_data['stock'],
            $variant_data['image_url'] ?? null
        );
        $stmt->execute();
        
        // Process attributes for this variant
        foreach ($variant_data['attributes'] as $attr_name => $attr_value) {
            // Check if attribute exists, if not create it
            $stmt = $conn->prepare("SELECT id FROM attributes WHERE name = ?");
            $stmt->bind_param("s", $attr_name);
            $stmt->execute();
            $result = $stmt->get_result();
            
            if ($result->num_rows === 0) {
                // Create new attribute
                $stmt = $conn->prepare("INSERT INTO attributes (name, created_by) VALUES (?, ?)");
                $stmt->bind_param("si", $attr_name, $user['id']);
                $stmt->execute();
                $attribute_id = $conn->insert_id;
            } else {
                $attribute_id = $result->fetch_assoc()['id'];
            }
            
            // Check if attribute value exists, if not create it
            $stmt = $conn->prepare("SELECT id FROM attribute_values WHERE attribute_id = ? AND value = ?");
            $stmt->bind_param("is", $attribute_id, $attr_value);
            $stmt->execute();
            $result = $stmt->get_result();
            
            if ($result->num_rows === 0) {
                // Create new attribute value
                $stmt = $conn->prepare("INSERT INTO attribute_values (attribute_id, value, created_by) VALUES (?, ?, ?)");
                $stmt->bind_param("isi", $attribute_id, $attr_value, $user['id']);
                $stmt->execute();
                $attribute_value_id = $conn->insert_id;
            } else {
                $attribute_value_id = $result->fetch_assoc()['id'];
            }
            
            // Link variant to attribute value
            $stmt = $conn->prepare("INSERT INTO variant_attribute_values (variant_id, attribute_value_id) VALUES (?, ?)");
            $stmt->bind_param("ii", $variant_id, $attribute_value_id);
            $stmt->execute();
        }
    }
    
    $conn->commit();
    
    // Send notification to admin
    $stmt = $conn->prepare("
        INSERT INTO notifications (user_id, title, content, type) 
        SELECT id, 'Sản phẩm mới cần duyệt', ?, 'product_approval'
        FROM users WHERE role = 'admin'
    ");
    $content = "Agency " . $user['username'] . " đã tạo sản phẩm mới: " . $data['name'];
    $stmt->bind_param("s", $content);
    $stmt->execute();
    
    sendResponse(201, 'Product created successfully and sent for approval', [
        'product_id' => $product_id,
        'message' => 'Product will be reviewed by admin'
    ]);
    
} catch (Exception $e) {
    if ($conn->connect_errno === 0) {
        $conn->rollback();
    }
    sendResponse(500, 'Error creating product: ' . $e->getMessage());
}

$conn->close();
?> 