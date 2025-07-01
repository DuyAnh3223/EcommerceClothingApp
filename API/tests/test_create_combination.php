<?php
// Test API tạo tổ hợp sản phẩm
$url = "http://127.0.0.1/EcommerceClothingApp/API/product_combinations/create_combination.php";

$data = [
    "name" => "Combo Test API",
    "description" => "Tổ hợp test tự động",
    "image_url" => "test_image.jpg",
    "discount_price" => 123000,
    "status" => "active",
    "created_by" => 6, // ID admin (sửa lại cho đúng user của bạn)
    "creator_type" => "admin",
    "categories" => ["T-Shirts", "Pants"],
    "items" => [
        [ "product_id" => 3, "quantity" => 1 ],
        [ "product_id" => 4, "quantity" => 1 ]
    ]
];

$options = [
    'http' => [
        'header'  => "Content-Type: application/json\r\n",
        'method'  => 'POST',
        'content' => json_encode($data),
    ],
];
$context  = stream_context_create($options);
$result = file_get_contents($url, false, $context);

if ($result === FALSE) {
    echo "Request failed!\n";
} else {
    echo "Response:\n";
    echo $result;
}

$name = $data['name'];
$description = $data['description'] ?? '';
$image_url = $data['image_url'] ?? null;
$discount_price = $data['discount_price'] ?? null;
$status = $data['status'] ?? 'active';
$created_by = $data['created_by'];
$creator_type = $data['creator_type'];

$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

$stmt = $conn->prepare("
    INSERT INTO product_combinations (
        name, description, image_url, discount_price, 
        status, created_by, creator_type
    ) VALUES (?, ?, ?, ?, ?, ?, ?)
");

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

$conn->close();
?>