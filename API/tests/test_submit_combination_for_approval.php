<?php
// Test API gửi duyệt tổ hợp sản phẩm
$url = "http://127.0.0.1/EcommerceClothingApp/API/product_combinations/submit_for_approval.php";

function callApi($data) {
    global $url;
    $options = [
        'http' => [
            'header'  => "Content-Type: application/json\r\n",
            'method'  => 'POST',
            'content' => json_encode($data),
        ],
    ];
    $context  = stream_context_create($options);
    $result = @file_get_contents($url, false, $context);
    if ($result === FALSE) {
        $error = error_get_last();
        return [
            'success' => false,
            'error' => $error['message'] ?? 'Unknown error',
            'response' => null
        ];
    }
    return [
        'success' => true,
        'response' => $result
    ];
}

$testCases = [
    [
        'desc' => 'Gửi duyệt thành công',
        'data' => ["combination_id" => 11], // Sửa lại ID hợp lệ của bạn
        'expectSuccess' => true
    ],
    [
        'desc' => 'Combination không tồn tại',
        'data' => ["combination_id" => 999999],
        'expectSuccess' => false
    ],
    [
        'desc' => 'Thiếu combination_id',
        'data' => [],
        'expectSuccess' => false
    ],
    [
        'desc' => 'Combination không thuộc agency',
        'data' => ["combination_id" => 1], // Sửa lại ID không thuộc agency
        'expectSuccess' => false
    ],
    [
        'desc' => 'Combination trạng thái active',
        'data' => ["combination_id" => 12], // Sửa lại ID trạng thái active
        'expectSuccess' => false
    ],
    [
        'desc' => 'Combination chỉ có 1 sản phẩm',
        'data' => ["combination_id" => 13], // Sửa lại ID chỉ có 1 sản phẩm
        'expectSuccess' => false
    ],
    [
        'desc' => 'Combination discount_price <= 0',
        'data' => ["combination_id" => 14], // Sửa lại ID discount_price <= 0
        'expectSuccess' => false
    ],
];

foreach ($testCases as $case) {
    echo "\n==== {$case['desc']} ====";
    $result = callApi($case['data']);
    if (!$result['success']) {
        echo "\nRequest failed: {$result['error']}\n";
        continue;
    }
    echo "\nRequest: ".json_encode($case['data']);
    echo "\nResponse: {$result['response']}\n";
    $json = json_decode($result['response'], true);
    if ($case['expectSuccess']) {
        if (isset($json['success']) && $json['success']) {
            echo "==> PASSED\n";
        } else {
            echo "==> FAILED (expected success)\n";
        }
    } else {
        if (isset($json['success']) && !$json['success']) {
            echo "==> PASSED\n";
        } else {
            echo "==> FAILED (expected failure)\n";
        }
    }
} 