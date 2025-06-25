<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../config/db_connect.php';

$product_id = isset($_GET['product_id']) ? (int)$_GET['product_id'] : null;
if ($product_id) {
    $sql = "SELECT ppv.product_variant_id, pv.color, pv.size, pv.material, ppv.price, ppv.stock, ppv.status, ppv.image_url
            FROM product_product_variant ppv
            JOIN product_variants pv ON ppv.product_variant_id = pv.id
            WHERE ppv.product_id = ?
            ORDER BY pv.color, pv.size";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $product_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $variants = [];
    while ($row = $result->fetch_assoc()) {
        $variants[] = [
            'id' => (int)$row['product_variant_id'],
            'color' => $row['color'],
            'size' => $row['size'],
            'material' => $row['material'],
            'price' => (float)$row['price'],
            'stock' => (int)$row['stock'],
            'status' => $row['status'],
            'image_url' => $row['image_url']
        ];
    }
    $stmt->close();
    http_response_code(200);
    echo json_encode(["success" => true, "variants" => $variants, "total_variants" => count($variants)]);
} else {
    $sql = "SELECT id, color, size, material FROM product_variants ORDER BY id";
    $result = $conn->query($sql);
    $variants = [];
    while ($row = $result->fetch_assoc()) {
        $variants[] = [
            'id' => (int)$row['id'],
            'color' => $row['color'],
            'size' => $row['size'],
            'material' => $row['material']
        ];
    }
    http_response_code(200);
    echo json_encode(["success" => true, "variants" => $variants, "total_variants" => count($variants)]);
}
$conn->close();
?>
