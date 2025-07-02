#!/bin/bash

echo "=== Test tạo Order với sản phẩm Agency ===\n"

# Test với sản phẩm agency (Product ID: 25, Variant ID: 28)
# Base Price: 200,000 VND, Platform Fee: 40,000 VND (20%), Final Price: 240,000 VND

echo "Test 1: Order với sản phẩm Agency (có platform fee)"
curl -X POST http://localhost/EcommerceClothingApp/API/orders/add_order.php \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 4,
    "address_id": 3,
    "items": [
      {
        "product_id": 25,
        "variant_id": 28,
        "quantity": 1
      }
    ],
    "status": "pending"
  }'

echo -e "\n\n=== Expected Results ==="
echo "Base Price: 200,000 VND"
echo "Platform Fee: 40,000 VND (20%)"
echo "Final Price: 240,000 VND"
echo "Total Amount: 240,000 VND"
echo "Platform Fee: 40,000 VND"

echo -e "\n\nTest 2: Order với sản phẩm Admin (không có platform fee)"
curl -X POST http://localhost/EcommerceClothingApp/API/orders/add_order.php \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 4,
    "address_id": 3,
    "items": [
      {
        "product_id": 3,
        "variant_id": 4,
        "quantity": 1
      }
    ],
    "status": "pending"
  }'

echo -e "\n\n=== Expected Results ==="
echo "Base Price: 10,000 VND"
echo "Platform Fee: 0 VND (không phải agency product)"
echo "Final Price: 10,000 VND"
echo "Total Amount: 10,000 VND"
echo "Platform Fee: 0 VND"

echo -e "\n\nTest 3: Order hỗn hợp (agency + admin)"
curl -X POST http://localhost/EcommerceClothingApp/API/orders/add_order.php \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 4,
    "address_id": 3,
    "items": [
      {
        "product_id": 25,
        "variant_id": 28,
        "quantity": 1
      },
      {
        "product_id": 3,
        "variant_id": 4,
        "quantity": 1
      }
    ],
    "status": "pending"
  }'

echo -e "\n\n=== Expected Results ==="
echo "Item 1 (Agency): 240,000 VND (200,000 + 40,000 platform fee)"
echo "Item 2 (Admin): 10,000 VND (không có platform fee)"
echo "Total Amount: 250,000 VND"
echo "Platform Fee: 40,000 VND" 