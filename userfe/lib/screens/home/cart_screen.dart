import 'package:flutter/material.dart';
import 'package:userfe/services/auth_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/vnpay_service.dart';

class CartScreen extends StatefulWidget {
  final VoidCallback? onCartUpdated;
  const CartScreen({Key? key, this.onCartUpdated}) : super(key: key);

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
    if (mounted) {
      setState(() { isLoading = true; });
    }
    final userData = await AuthService.getUserData();
    final userId = userData?['id'];
    if (userId == null) {
      if (mounted) {
        setState(() { isLoading = false; });
      }
      return;
    }
    final result = await AuthService.getCart(userId: userId);
    if (result['success'] == true && result['data'] is List) {
      if (mounted) {
        setState(() {
          cartItems = result['data'];
          isLoading = false;
        });
        
        // Debug: In ra thông tin giỏ hàng để kiểm tra
        print('=== DEBUG CART ===');
        for (var item in cartItems) {
          print('Product: ${item['product_name']}');
          print('Product Image: ${item['product_image']}');
          print('Variant Image: ${item['variant_image']}');
          print('Final Image URL: ${item['image_url']}');
          print('Attributes: ${item['attributes']}');
          print('---');
        }
      }
    } else {
      if (mounted) {
        setState(() { isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Lỗi tải giỏ hàng'), backgroundColor: Colors.red),
        );
      }
    }
  }

  double get totalPrice => cartItems.fold<double>(0, (sum, item) => sum + (item['total_price'] ?? 0));

  Future<void> _updateQuantity(int cartItemId, int newQuantity) async {
    print('=== DEBUG: Updating cart quantity ===');
    final result = await AuthService.updateCart(cartItemId: cartItemId, quantity: newQuantity);
    if (result['success'] == true) {
      await _loadCart();
      // Notify parent screen to update cart count
      print('DEBUG: Calling onCartUpdated callback after quantity update');
      widget.onCartUpdated?.call();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Lỗi cập nhật số lượng'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteItem(int cartItemId) async {
    print('=== DEBUG: Deleting cart item ===');
    final result = await AuthService.deleteCartItem(cartItemId: cartItemId);
    if (result['success'] == true) {
      await _loadCart();
      // Notify parent screen to update cart count
      print('DEBUG: Calling onCartUpdated callback after item deletion');
      widget.onCartUpdated?.call();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Lỗi xóa sản phẩm'), backgroundColor: Colors.red),
      );
    }
  }

  void _showOrderConfirmDialog() {
    if (cartItems.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => CartOrderConfirmDialog(
        cartItems: cartItems,
        totalPrice: totalPrice,
        onOrderPlaced: () {
          print('=== DEBUG: Order placed, updating cart ===');
          Navigator.of(context).pop(); // Close dialog
          _loadCart(); // Reload cart to clear it
          // Notify parent screen to update cart count
          print('DEBUG: Calling onCartUpdated callback after order placement');
          widget.onCartUpdated?.call();
        },
      ),
    );
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
                                  GestureDetector(
                                    onTap: () {
                                      if (item['image_url'] != null && item['image_url'] != '') {
                                        showDialog(
                                          context: context,
                                          builder: (context) => Dialog(
                                            child: Container(
                                              constraints: BoxConstraints(
                                                maxWidth: MediaQuery.of(context).size.width * 0.9,
                                                maxHeight: MediaQuery.of(context).size.height * 0.8,
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  AppBar(
                                                    title: Text('Hình ảnh: ${item['product_name']}'),
                                                    backgroundColor: Colors.transparent,
                                                    elevation: 0,
                                                    actions: [
                                                      IconButton(
                                                        icon: const Icon(Icons.close),
                                                        onPressed: () => Navigator.of(context).pop(),
                                                      ),
                                                    ],
                                                  ),
                                                  Expanded(
                                                    child: CachedNetworkImage(
                                                      imageUrl: 'http://127.0.0.1/EcommerceClothingApp/API/uploads/serve_image.php?file=${item['image_url']}',
                                                      fit: BoxFit.contain,
                                                      placeholder: (context, url) => const Center(
                                                        child: CircularProgressIndicator(),
                                                      ),
                                                      errorWidget: (context, url, error) => const Center(
                                                        child: Column(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            Icon(Icons.error, size: 64, color: Colors.red),
                                                            SizedBox(height: 8),
                                                            Text('Lỗi tải hình ảnh', style: TextStyle(color: Colors.red)),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    child: Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Stack(
                                        children: [
                                          item['image_url'] != null && item['image_url'] != ''
                                              ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: CachedNetworkImage(
                                                    imageUrl: 'http://127.0.0.1/EcommerceClothingApp/API/uploads/serve_image.php?file=${item['image_url']}',
                                                    width: 64,
                                                    height: 64,
                                                    fit: BoxFit.cover,
                                                    placeholder: (context, url) => const Center(
                                                      child: CircularProgressIndicator(),
                                                    ),
                                                    errorWidget: (context, url, error) => const Icon(
                                                      Icons.image,
                                                      size: 30,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                )
                                              : const Icon(
                                                  Icons.image,
                                                  size: 30,
                                                  color: Colors.grey,
                                                ),
                                          // Icon zoom khi có hình ảnh
                                          if (item['image_url'] != null && item['image_url'] != '')
                                            Positioned(
                                              top: 2,
                                              right: 2,
                                              child: Container(
                                                padding: const EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withOpacity(0.6),
                                                  borderRadius: BorderRadius.circular(2),
                                                ),
                                                child: const Icon(
                                                  Icons.zoom_in,
                                                  color: Colors.white,
                                                  size: 12,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item['product_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text(attrs, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                        const SizedBox(height: 4),
                                        // Hiển thị giá và thông tin phí sàn
                                        if (item['is_agency_product'] == true && item['platform_fee'] > 0) ...[
                                          Text('Giá gốc: ${item['base_price'].toStringAsFixed(0)} VNĐ', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                          Text('Phí sàn (${item['platform_fee_rate']}%): +${item['platform_fee'].toStringAsFixed(0)} VNĐ', style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
                                          Text('Giá cuối: ${item['price'].toStringAsFixed(0)} VNĐ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade700)),
                                        ] else ...[
                                          Text('Giá: ${item['price'].toStringAsFixed(0)} VNĐ'),
                                        ],
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
                                _showOrderConfirmDialog();
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

class CartOrderConfirmDialog extends StatefulWidget {
  final List cartItems;
  final double totalPrice;
  final VoidCallback onOrderPlaced;

  const CartOrderConfirmDialog({
    Key? key,
    required this.cartItems,
    required this.totalPrice,
    required this.onOrderPlaced,
  }) : super(key: key);

  @override
  State<CartOrderConfirmDialog> createState() => _CartOrderConfirmDialogState();
}

class _CartOrderConfirmDialogState extends State<CartOrderConfirmDialog> {
  List addresses = [];
  int? selectedAddressId;
  String paymentMethod = 'COD';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final userData = await AuthService.getUserData();
    final userId = userData?['id'];
    if (userId == null) return;
    final result = await AuthService.getUserAddresses(userId: userId);
    if (result['success'] == true && result['data'] is List && result['data'].isNotEmpty) {
      setState(() {
        addresses = result['data'];
        selectedAddressId = addresses.firstWhere((a) => a['is_default'] == true, orElse: () => addresses[0])['id'];
      });
    }
  }

  Future<void> _placeOrder() async {
    final userData = await AuthService.getUserData();
    final userId = userData?['id'];
    if (userId == null || selectedAddressId == null) return;
    setState(() { isLoading = true; });
    
    try {
      final items = widget.cartItems.map((item) => {
        'product_id': item['product_id'],
        'variant_id': item['variant_id'],
        'quantity': item['quantity'],
      }).toList();
      final result = await AuthService.placeOrderMulti(
        userId: userId,
        addressId: selectedAddressId!,
        paymentMethod: paymentMethod,
        items: items,
      );
      
      if (result['success'] == true) {
        // Xóa items khỏi giỏ hàng
        for (var item in widget.cartItems) {
          await AuthService.deleteCartItem(cartItemId: item['cart_item_id']);
        }
        setState(() { isLoading = false; });
        widget.onOrderPlaced();
        
        // Kiểm tra nếu cần thanh toán VNPAY
        if (result['requires_payment'] == true && result['payment_method'] == 'VNPAY') {
          // Hiển thị dialog thanh toán VNPAY
          _showVNPayPaymentDialog(result['payment_url'], result['order_id']);
        } else {
          // Thanh toán thường (COD, etc.)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text('🎉 Đặt hàng thành công!'),
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Xem đơn hàng', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        setState(() { isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? '❌ Có lỗi xảy ra khi đặt hàng.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() { isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showVNPayPaymentDialog(String paymentUrl, int orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.payment, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            const Text('Thanh toán VNPAY'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Đơn hàng đã được tạo thành công!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Mã đơn hàng: #$orderId',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              'Bạn sẽ được chuyển đến trang thanh toán VNPAY để hoàn tất giao dịch.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bạn có thể thanh toán sau trong phần đơn hàng'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Thanh toán sau'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await VNPayService.openPaymentUrl(paymentUrl);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã mở trang thanh toán VNPAY'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi mở trang thanh toán: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('💳 Thanh toán ngay'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Xác nhận đơn hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const Divider(),
              
              // Cart items summary
              const Text('Sản phẩm trong giỏ hàng:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.cartItems.length,
                  itemBuilder: (context, index) {
                    final item = widget.cartItems[index];
                    final attrs = (item['attributes'] as Map).entries.map((e) => '${e.key}: ${e.value}').join(' / ');
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: item['image_url'] != null && item['image_url'] != ''
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: CachedNetworkImage(
                                        imageUrl: 'http://127.0.0.1/EcommerceClothingApp/API/uploads/serve_image.php?file=${item['image_url']}',
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                        errorWidget: (context, url, error) => const Icon(
                                          Icons.image,
                                          size: 20,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.image,
                                      size: 20,
                                      color: Colors.grey,
                                    ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['product_name'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    attrs,
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'SL: ${item['quantity']} x ${item['price']} VNĐ',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${(item['total_price']).toStringAsFixed(0)} VNĐ',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Address selection
              const Text('Địa chỉ nhận hàng:'),
              addresses.isEmpty
                  ? const Text('Không có địa chỉ. Vui lòng thêm địa chỉ trong tài khoản.', style: TextStyle(color: Colors.red))
                  : DropdownButton<int>(
                      value: selectedAddressId,
                      isExpanded: true,
                      items: addresses.map<DropdownMenuItem<int>>((a) => DropdownMenuItem(
                        value: a['id'],
                        child: Text('${a['address_line']}, ${a['city']}, ${a['province']}'),
                      )).toList(),
                      onChanged: (v) => setState(() => selectedAddressId = v),
                    ),
              
              const SizedBox(height: 8),
              
              // Payment method
              const Text('Phương thức thanh toán:'),
              DropdownButton<String>(
                value: paymentMethod,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'COD', child: Text('Thanh toán khi nhận hàng (COD)')),
                 // DropdownMenuItem(value: 'Bank', child: Text('Chuyển khoản ngân hàng')),
                 // DropdownMenuItem(value: 'Momo', child: Text('Ví Momo')),
                  DropdownMenuItem(value: 'VNPAY', child: Text('VNPAY')),
                ],
                onChanged: (v) => setState(() => paymentMethod = v ?? 'COD'),
              ),
              
              const SizedBox(height: 12),
              
              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tổng tiền:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('${widget.totalPrice.toStringAsFixed(0)} VNĐ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (isLoading || selectedAddressId == null) ? null : _placeOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Xác nhận đặt hàng'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 