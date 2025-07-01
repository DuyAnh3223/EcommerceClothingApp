
<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Access-Control-Allow-Headers,Content-Type,Access-Control-Allow-Methods,Authorization,X-Requested-With');

include_once '../config/db_connect.php';
include_once '../utils/response.php';
include_once '../utils/auth.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(405, 'Method not allowed');
    exit();
}

try {
    $input = json_decode(file_get_contents('php://input'), true);
    
    // Validate required fields
    if (empty($input['name'])) {
        sendResponse(false, 'Tên tổ hợp sản phẩm không được để trống');
        exit();
    }
    
    if (empty($input['items']) || !is_array($input['items']) || count($input['items']) < 1) {
        sendResponse(false, 'Tổ hợp phải có ít nhất 1 sản phẩm');
        exit();
    }
    
    if (empty($input['categories']) || !is_array($input['categories']) || count($input['categories']) < 1) {
        sendResponse(false, 'Tổ hợp phải có ít nhất 1 danh mục');
        exit();
    }
    
    // Check for duplicate categories
    if (count($input['categories']) !== count(array_unique($input['categories']))) {
        sendResponse(false, 'Không được lặp danh mục trong tổ hợp');
        exit();
    }
    
    // Validate creator info
    $creator_type = $input['creator_type'] ?? 'admin';
    if (!in_array($creator_type, ['admin', 'agency'])) {
        sendResponse(false, 'Loại người tạo không hợp lệ');
        exit();
    }
    
    $created_by = $input['created_by'] ?? null;
    if (!$created_by) {
        sendResponse(false, 'ID người tạo không được để trống');
        exit();
    }
    
    // Start transaction
    $conn->begin_transaction();
    
    try {
        // Gán biến trước khi bind_param
        $name = $input['name'];
        $description = isset($input['description']) ? $input['description'] : '';
        $image_url = isset($input['image_url']) ? $input['image_url'] : null;
        $discount_price = isset($input['discount_price']) ? $input['discount_price'] : null;
        $status = isset($input['status']) ? $input['status'] : 'active';
        // $created_by và $creator_type đã có ở trên

        // Insert combination
        $stmt = $conn->prepare("
            INSERT INTO product_combinations (
                name, description, image_url, discount_price, 
                status, created_by, creator_type
            ) VALUES (?, ?, ?, ?, ?, ?, ?)
        ");
        // Kiểu dữ liệu: s = string, d = double, i = integer
        $stmt->bind_param(
            "sssdsis",
            $name,
            $description,
            $image_url,
            $discount_price,
            $status,
            $created_by,
            $creator_type
        );
        $stmt->execute();
        $combination_id = $conn->insert_id;
        
        // Insert categories
        $cat_stmt = $conn->prepare("
            INSERT INTO product_combination_categories (combination_id, category_name) 
            VALUES (?, ?)
        ");
        
        foreach ($input['categories'] as $category) {
            $cat_stmt->bind_param("is", $combination_id, $category);
            $cat_stmt->execute();
        }
        
        // Insert items
        $item_stmt = $conn->prepare("
            INSERT INTO product_combination_items (
                combination_id, product_id, variant_id, quantity, price_in_combination
            ) VALUES (?, ?, ?, ?, ?)
        ");
        
        foreach ($input['items'] as $item) {
            // Validate product exists and belongs to creator
            $product_query = "
                SELECT p.* FROM products p 
                WHERE p.id = ? AND p.created_by = ?
            ";
            $prod_stmt = $conn->prepare($product_query);
            $prod_stmt->bind_param("ii", $item['product_id'], $created_by);
            $prod_stmt->execute();
            $product = $prod_stmt->get_result()->fetch_assoc();
            
            if (!$product) {
                throw new Exception("Sản phẩm ID {$item['product_id']} không tồn tại hoặc không thuộc quyền sở hữu của bạn");
            }
            
            // Check if variant exists (if provided)
            if (!empty($item['variant_id'])) {
                $variant_query = "
                    SELECT pv.* FROM product_variant pv 
                    WHERE pv.product_id = ? AND pv.variant_id = ?
                ";
                $var_stmt = $conn->prepare($variant_query);
                $var_stmt->bind_param("ii", $item['product_id'], $item['variant_id']);
                $var_stmt->execute();
                $variant = $var_stmt->get_result()->fetch_assoc();
                
                if (!$variant) {
                    throw new Exception("Biến thể ID {$item['variant_id']} không tồn tại cho sản phẩm ID {$item['product_id']}");
                }
            }
            
            $product_id = $item['product_id'];
            $variant_id = isset($item['variant_id']) ? $item['variant_id'] : null;
            $quantity = isset($item['quantity']) ? $item['quantity'] : 1;
            $price_in_combination = isset($item['price_in_combination']) ? $item['price_in_combination'] : null;

            $item_stmt->bind_param(
                "iiidd",
                $combination_id,
                $product_id,
                $variant_id,
                $quantity,
                $price_in_combination
            );
            $item_stmt->execute();
        }
        
        // Commit transaction
        $conn->commit();
        
        sendResponse(true, 'Tạo tổ hợp sản phẩm thành công', [
            'combination_id' => $combination_id
        ]);
        
    } catch (Exception $e) {
        $conn->rollback();
        throw $e;
    }
    
} catch (Exception $e) {
    sendResponse(false, 'Lỗi tạo tổ hợp sản phẩm: ' . $e->getMessage(), null, 500);
}

$conn->close();
?> 