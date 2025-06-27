import 'package:flutter/material.dart';
import 'package:userfe/services/auth_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List cartItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() { isLoading = true; });
    final userData = await AuthService.getUserData();
    final userId = userData?['id'];
    if (userId == null) {
      setState(() { isLoading = false; });
      return;
    }
    final result = await AuthService.getCart(userId: userId);
    if (result['success'] == true && result['data'] is List) {
      setState(() {
        cartItems = result['data'];
        isLoading = false;
      });
    } else {
      setState(() { isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Lỗi tải giỏ hàng'), backgroundColor: Colors.red),
      );
    }
  }

  double get totalPrice => cartItems.fold<double>(0, (sum, item) => sum + (item['total_price'] ?? 0));

  Future<void> _updateQuantity(int cartItemId, int newQuantity) async {
    final result = await AuthService.updateCart(cartItemId: cartItemId, quantity: newQuantity);
    if (result['success'] == true) {
      await _loadCart();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Lỗi cập nhật số lượng'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteItem(int cartItemId) async {
    final result = await AuthService.deleteCartItem(cartItemId: cartItemId);
    if (result['success'] == true) {
      await _loadCart();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Lỗi xóa sản phẩm'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giỏ hàng'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : cartItems.isEmpty
              ? const Center(child: Text('Giỏ hàng trống'))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        itemCount: cartItems.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final item = cartItems[index];
                          final attrs = (item['attributes'] as Map).entries.map((e) => '${e.key}: ${e.value}').join(' / ');
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  item['image_url'] != null && item['image_url'] != ''
                                      ? Image.network(item['image_url'], width: 64, height: 64, fit: BoxFit.cover)
                                      : const Icon(Icons.image, size: 64, color: Colors.grey),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item['product_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text(attrs, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                        const SizedBox(height: 4),
                                        Text('Giá: ${item['price']} VNĐ'),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove_circle_outline),
                                              onPressed: item['quantity'] > 1
                                                  ? () => _updateQuantity(item['cart_item_id'], item['quantity'] - 1)
                                                  : null,
                                            ),
                                            Text('${item['quantity']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                            IconButton(
                                              icon: const Icon(Icons.add_circle_outline),
                                              onPressed: item['quantity'] < item['stock']
                                                  ? () => _updateQuantity(item['cart_item_id'], item['quantity'] + 1)
                                                  : null,
                                            ),
                                            const SizedBox(width: 8),
                                            Text('Thành tiền: ${(item['total_price']).toStringAsFixed(0)} VNĐ', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteItem(item['cart_item_id']),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tổng cộng:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('${totalPrice.toStringAsFixed(0)} VNĐ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange.shade700)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('⬅️ Tiếp tục mua sắm'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: cartItems.isEmpty ? null : () {
                                // TODO: Đặt hàng
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Tính năng đặt hàng đang phát triển!'), backgroundColor: Colors.blue),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade700,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('🛒 Đặt hàng'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
} 