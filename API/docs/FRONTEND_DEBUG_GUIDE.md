# Hướng Dẫn Debug Frontend - Order API

## Lỗi "Thiếu thông tin đầu vào"

### Nguyên nhân:
Frontend không gửi đúng format dữ liệu đến API `place_order_with_combinations.php`

### Cách Debug:

#### 1. Kiểm tra request từ Flutter/Dart
```dart
// Kiểm tra dữ liệu trước khi gửi
print('Request data: ${jsonEncode(requestData)}');

// Kiểm tra response
try {
  final response = await http.post(
    Uri.parse('http://127.0.0.1/EcommerceClothingApp/API/orders/place_order_with_combinations.php'),
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode(requestData),
  );
  
  print('Response status: ${response.statusCode}');
  print('Response body: ${response.body}');
  
  if (response.statusCode == 400) {
    final errorData = jsonDecode(response.body);
    print('Error details: ${errorData['debug_info']}');
  }
} catch (e) {
  print('Request error: $e');
}
```

#### 2. Format dữ liệu đúng
```dart
// Format đúng cho API
final requestData = {
  'user_id': userId, // int
  'address_id': addressId, // int
  'payment_method': paymentMethod, // string: 'BACoin', 'VNPAY', 'COD'
  'cart_items': [
    {
      'type': 'product', // hoặc 'combination'
      'product_id': productId, // int
      'variant_id': variantId, // int
      'quantity': quantity, // int
      // Nếu là combination:
      // 'combination_id': combinationId,
      // 'combination_price': combinationPrice,
    }
  ]
};
```

#### 3. Kiểm tra từng field
```dart
// Debug từng field
print('user_id: $userId (${userId.runtimeType})');
print('address_id: $addressId (${addressId.runtimeType})');
print('payment_method: $paymentMethod');
print('cart_items: ${cartItems.length} items');

// Kiểm tra cart_items
for (int i = 0; i < cartItems.length; i++) {
  final item = cartItems[i];
  print('Item $i: ${jsonEncode(item)}');
}
```

### Các lỗi thường gặp:

#### 1. "user_id=0"
- Kiểm tra `userId` có được truyền đúng không
- Kiểm tra kiểu dữ liệu (phải là int)
- Kiểm tra user đã đăng nhập chưa

#### 2. "address_id=0"
- Kiểm tra `addressId` có được chọn không
- Kiểm tra address có tồn tại trong database không

#### 3. "cart_items_count=0"
- Kiểm tra `cartItems` có dữ liệu không
- Kiểm tra format của từng item trong cart
- Kiểm tra `type` field (product/combination)

### Test với curl:

#### Test JSON format:
```bash
curl -X POST http://127.0.0.1/EcommerceClothingApp/API/orders/place_order_with_combinations.php \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 1,
    "address_id": 1,
    "payment_method": "BACoin",
    "cart_items": [
      {
        "type": "product",
        "product_id": 1,
        "variant_id": 1,
        "quantity": 1
      }
    ]
  }'
```

#### Test form data:
```bash
curl -X POST http://127.0.0.1/EcommerceClothingApp/API/orders/place_order_with_combinations.php \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "user_id=1&address_id=1&payment_method=BACoin&cart_items=[{\"type\":\"product\",\"product_id\":1,\"variant_id\":1,\"quantity\":1}]"
```

### Debug từ Flutter:

#### 1. Thêm logging chi tiết:
```dart
class OrderService {
  Future<Map<String, dynamic>> placeOrder({
    required int userId,
    required int addressId,
    required String paymentMethod,
    required List<Map<String, dynamic>> cartItems,
  }) async {
    final requestData = {
      'user_id': userId,
      'address_id': addressId,
      'payment_method': paymentMethod,
      'cart_items': cartItems,
    };

    print('=== Order Request Debug ===');
    print('URL: ${ApiConfig.baseUrl}/orders/place_order_with_combinations.php');
    print('Request data: ${jsonEncode(requestData)}');
    print('Headers: {"Content-Type": "application/json"}');

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/orders/place_order_with_combinations.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData),
      );

      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        print('Error response: ${jsonEncode(errorData)}');
        throw Exception(errorData['message'] ?? 'Unknown error');
      }
    } catch (e) {
      print('Request exception: $e');
      rethrow;
    }
  }
}
```

#### 2. Kiểm tra dữ liệu trước khi gửi:
```dart
// Trong widget hoặc service
void placeOrder() async {
  // Validate data
  if (userId == null || userId == 0) {
    print('ERROR: user_id is null or 0');
    return;
  }
  
  if (addressId == null || addressId == 0) {
    print('ERROR: address_id is null or 0');
    return;
  }
  
  if (cartItems.isEmpty) {
    print('ERROR: cart_items is empty');
    return;
  }
  
  // Log cart items
  for (int i = 0; i < cartItems.length; i++) {
    final item = cartItems[i];
    print('Cart item $i: ${jsonEncode(item)}');
  }
  
  // Proceed with order
  try {
    final result = await orderService.placeOrder(
      userId: userId,
      addressId: addressId,
      paymentMethod: paymentMethod,
      cartItems: cartItems,
    );
    print('Order success: ${jsonEncode(result)}');
  } catch (e) {
    print('Order failed: $e');
  }
}
```

### Kiểm tra Database:

#### 1. Kiểm tra user:
```sql
SELECT id, username, balance FROM users WHERE id = 1;
```

#### 2. Kiểm tra address:
```sql
SELECT id, user_id, address FROM addresses WHERE id = 1;
```

#### 3. Kiểm tra products:
```sql
SELECT id, name, status FROM products WHERE id = 1;
SELECT product_id, variant_id, price, stock FROM product_variant WHERE product_id = 1;
```

### Chạy test API:
```bash
php API/test_order_formats.php
``` 