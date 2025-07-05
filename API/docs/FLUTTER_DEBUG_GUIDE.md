# Flutter Debug Guide for place_order_with_combinations.php

## Issue: 400 Bad Request Error

You're getting a 400 Bad Request error when calling the `place_order_with_combinations.php` API. Here's how to debug and fix this issue.

## Step 1: Check the Request Data

Add this debug code to your Flutter app before making the API call:

```dart
// Debug: Log the request data
void debugOrderRequest({
  required int userId,
  required int addressId,
  required String paymentMethod,
  required List<Map<String, dynamic>> cartItems,
}) {
  final requestData = {
    'user_id': userId,
    'address_id': addressId,
    'payment_method': paymentMethod,
    'cart_items': cartItems,
  };
  
  print('=== DEBUG ORDER REQUEST ===');
  print('Request URL: ${AuthService.baseUrl}/orders/place_order_with_combinations.php');
  print('Request Data: ${json.encode(requestData)}');
  print('Cart Items Count: ${cartItems.length}');
  
  // Validate each cart item
  for (int i = 0; i < cartItems.length; i++) {
    final item = cartItems[i];
    print('Item $i: ${json.encode(item)}');
    
    // Check required fields
    if (item['type'] == 'product') {
      if (item['product_id'] == null) print('ERROR: Missing product_id in item $i');
      if (item['variant_id'] == null) print('ERROR: Missing variant_id in item $i');
      if (item['quantity'] == null) print('ERROR: Missing quantity in item $i');
    } else if (item['type'] == 'combination') {
      if (item['combination_id'] == null) print('ERROR: Missing combination_id in item $i');
      if (item['quantity'] == null) print('ERROR: Missing quantity in item $i');
      if (item['combination_price'] == null) print('ERROR: Missing combination_price in item $i');
    }
  }
  print('=== END DEBUG ===');
}
```

## Step 2: Update the AuthService Method

Update your `placeOrderWithCombinations` method in `auth_service.dart`:

```dart
static Future<Map<String, dynamic>> placeOrderWithCombinations({
  required int userId,
  required int addressId,
  required String paymentMethod,
  required List<Map<String, dynamic>> cartItems,
}) async {
  try {
    // Debug: Log request data
    debugOrderRequest(
      userId: userId,
      addressId: addressId,
      paymentMethod: paymentMethod,
      cartItems: cartItems,
    );
    
    final requestData = {
      'user_id': userId,
      'address_id': addressId,
      'payment_method': paymentMethod,
      'cart_items': cartItems,
    };
    
    print('Making API request...');
    final response = await http.post(
      Uri.parse('$baseUrl/orders/place_order_with_combinations.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(requestData),
    );
    
    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');
    
    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      print('Success Response: ${json.encode(result)}');
      return result;
    } else {
      print('Error Response: ${response.body}');
      return {
        'success': false,
        'message': 'Lỗi kết nối server: ${response.statusCode}',
        'response_body': response.body,
      };
    }
  } catch (e) {
    print('Exception: $e');
    return {
      'success': false,
      'message': 'Lỗi kết nối: $e',
    };
  }
}
```

## Step 3: Validate Cart Items Structure

Make sure your cart items have the correct structure:

### For Individual Products:
```dart
{
  'type': 'product',
  'product_id': 1,  // int
  'variant_id': 1,  // int
  'quantity': 1     // int
}
```

### For Combinations:
```dart
{
  'type': 'combination',
  'combination_id': 1,        // int
  'quantity': 1,              // int
  'combination_price': 100000 // double
}
```

## Step 4: Test with Sample Data

Create a test function to verify the API works:

```dart
Future<void> testOrderAPI() async {
  final testCartItems = [
    {
      'type': 'product',
      'product_id': 1,
      'variant_id': 1,
      'quantity': 1
    }
  ];
  
  final result = await AuthService.placeOrderWithCombinations(
    userId: 1,
    addressId: 1,
    paymentMethod: 'BACoin',
    cartItems: testCartItems,
  );
  
  print('Test Result: ${json.encode(result)}');
}
```

## Step 5: Check Common Issues

### 1. Data Type Issues
Make sure all IDs are integers, not strings:
```dart
// WRONG
'product_id': '1'

// CORRECT
'product_id': 1
```

### 2. Missing Required Fields
Ensure all required fields are present:
- `user_id` (int)
- `address_id` (int)
- `payment_method` (string)
- `cart_items` (array)

### 3. Cart Items Validation
Each cart item must have:
- `type` (string: 'product' or 'combination')
- For products: `product_id`, `variant_id`, `quantity`
- For combinations: `combination_id`, `quantity`, `combination_price`

## Step 6: Run the Debug Test

1. Run the PHP debug script:
```bash
php API/test_debug_order.php
```

2. Add debug logging to your Flutter app and check the console output.

3. Compare the request data with the expected format.

## Step 7: Common Solutions

### If you get "Missing required fields":
- Check that `user_id` and `address_id` are valid integers
- Ensure `cart_items` is not empty
- Verify each cart item has the correct structure

### If you get "Product not found":
- Check that the product_id and variant_id exist in the database
- Ensure the product and variant are active

### If you get "Insufficient BACoin balance":
- Check the user's BACoin balance
- Verify the total amount calculation

## Step 8: Example Usage

```dart
// Example: Place order with individual products
final cartItems = [
  {
    'type': 'product',
    'product_id': 1,
    'variant_id': 1,
    'quantity': 2
  },
  {
    'type': 'product',
    'product_id': 2,
    'variant_id': 3,
    'quantity': 1
  }
];

final result = await AuthService.placeOrderWithCombinations(
  userId: currentUser['id'],
  addressId: selectedAddress['id'],
  paymentMethod: 'BACoin',
  cartItems: cartItems,
);

if (result['success']) {
  print('Order placed successfully!');
  print('Order ID: ${result['order_id']}');
} else {
  print('Error: ${result['message']}');
}
```

## Step 9: Check Server Logs

If the issue persists, check the PHP error logs:
- Look for error messages in your web server logs
- Check the debug logs we added to the API
- Verify database connectivity

## Step 10: Database Validation

Make sure these tables exist and have data:
- `users` (with valid user_id)
- `addresses` (with valid address_id)
- `products` (with valid product_id)
- `product_variant` (with valid product_id and variant_id)
- `product_combinations` (if using combinations)

This debug guide should help you identify and fix the 400 error issue. 