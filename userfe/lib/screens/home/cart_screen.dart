import 'package:flutter/material.dart';
import 'package:userfe/services/auth_service.dart';
import 'package:userfe/services/notification_service.dart';
import 'package:userfe/services/voucher_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/vnpay_service.dart';

class CartScreen extends StatefulWidget {
  final VoidCallback? onCartUpdated;
  const CartScreen({Key? key, this.onCartUpdated}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<dynamic> cartItems = [];
  bool isLoading = true;
  double originalTotal = 0.0;
  double finalTotal = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadCart() async {
    if (mounted) {
      setState(() { isLoading = true; });
    }
    final userData = await AuthService.getUserData();
    final userId = userData?['id'];
    if (userId == null) return;
    final result = await AuthService.getCart(userId: userId);
    if (result['success'] == true && result['data'] is List) {
      if (mounted) {
        setState(() {
          cartItems = result['data'];
          isLoading = false;
        });
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

  Future<void> _loadNotificationCount() async {
    final userData = await AuthService.getUserData();
    final userId = userData?['id'];
    if (userId == null) return;
    
    final result = await NotificationService.getUnreadCount(userId: userId);
    if (result['success'] == true && result['data'] != null && mounted) {
      // Notification count will be updated in parent widget
      print('DEBUG: Notification count refreshed after order placement');
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
          // Refresh notification count after successful order
          _loadNotificationCount();
        },
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item) {
    if (item['type'] == 'combination') {
      return _buildCombinationItem(item);
    } else {
      return _buildProductItem(item);
    }
  }

  Widget _buildCombinationItem(Map<String, dynamic> item) {
    // Xác định hình ảnh cho combo: ưu tiên combination_image, nếu không có thì dùng image_url (sản phẩm đầu tiên)
    final comboImage = item['combination_image'] ?? item['image_url'] ?? '';
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        leading: GestureDetector(
          onTap: () {
            if (comboImage.isNotEmpty) {
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
                          title: Text('Hình ảnh: ${item['combination_name']}'),
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
                            imageUrl: 'http://127.0.0.1/EcommerceClothingApp/API/uploads/serve_image.php?file=$comboImage',
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
                comboImage.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: 'http://127.0.0.1/EcommerceClothingApp/API/uploads/serve_image.php?file=$comboImage',
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
                if (comboImage.isNotEmpty)
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
        title: Text(
          item['combination_name'] ?? 'Combo',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Giá combo: ${item['combination_price'].toStringAsFixed(0)} VNĐ',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
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
                  onPressed: () => _updateQuantity(item['cart_item_id'], item['quantity'] + 1),
                ),
                const SizedBox(width: 8),
                Text('Thành tiền: ${item['total_price'].toStringAsFixed(0)} VNĐ <=> BACoin', style: const TextStyle(fontWeight: FontWeight.bold)),
                // Text('Giá BACoin: '
                //   '${item['price_bacoin'] != null
                //       ? (item['price_bacoin'] is num
                //           ? item['price_bacoin'].toInt()
                //           : int.tryParse(item['price_bacoin'].toString()) ?? 0
                //         )
                //       : 0
                //   } Coin',
                //   style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                // ),
                // Text('Thành tiền BACoin: '
                //   '${item['price_bacoin'] != null
                //       ? ((item['price_bacoin'] is num
                //             ? item['price_bacoin']
                //             : int.tryParse(item['price_bacoin'].toString()) ?? 0
                //           ) * (item['quantity'] ?? 1)).toInt()
                //       : 0
                //   } Coin',
                //   style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                // ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _deleteItem(item['cart_item_id']),
        ),
        children: [
          // Hiển thị danh sách sản phẩm trong combo
          if (item['combination_items'] != null && item['combination_items'] is List)
            ...(item['combination_items'] as List).map<Widget>((comboItem) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: comboItem['image_url'] != null && comboItem['image_url'] != ''
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: CachedNetworkImage(
                                imageUrl: 'http://127.0.0.1/EcommerceClothingApp/API/uploads/serve_image.php?file=${comboItem['image_url']}',
                                width: 40,
                                height: 40,
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
                              Icons.inventory,
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
                            comboItem['product_name'] ?? 'Sản phẩm ID: ${comboItem['product_id']}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          if (comboItem['attributes'] != null && comboItem['attributes'] is Map)
                            Text(
                              (comboItem['attributes'] as Map).entries.map((e) => '${e.key}: ${e.value}').join(' / '),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          Text(
                            'Số lượng: ${comboItem['quantity']}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildProductItem(Map<String, dynamic> item) {
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
                      Text('Thành tiền: ${(item['total_price']).toStringAsFixed(0)} VNĐ <=> BACoin', style: const TextStyle(fontWeight: FontWeight.bold)),
                      // Text('Giá BACoin: '
                      //   '${item['price_bacoin'] != null
                      //       ? (item['price_bacoin'] is num
                      //           ? item['price_bacoin'].toInt()
                      //           : int.tryParse(item['price_bacoin'].toString()) ?? 0
                      //         )
                      //       : 0
                      //   } Coin',
                      //   style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                      // ),
                      // Text('Thành tiền BACoin: '
                      //   '${item['price_bacoin'] != null
                      //       ? ((item['price_bacoin'] is num
                      //             ? item['price_bacoin']
                      //             : int.tryParse(item['price_bacoin'].toString()) ?? 0
                      //           ) * (item['quantity'] ?? 1)).toInt()
                      //       : 0
                      //   } Coin',
                      //   style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                      // ),
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
                          return _buildCartItem(item);
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tổng cộng:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('${totalPrice.toStringAsFixed(0)} VNĐ <=> BACoin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange.shade700)),
                        ],
                      ),
                    ),
                    if (cartItems.isNotEmpty) ...[
                      // Padding(
                      //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      //   child: Text(
                      //     'Tổng BACoin: '
                      //     '${cartItems.fold<int>(0, (sum, item) {
                      //       final price = item['price_bacoin'] != null
                      //           ? (item['price_bacoin'] is num
                      //               ? (item['price_bacoin'] as num).toInt()
                      //               : int.tryParse(item['price_bacoin'].toString()) ?? 0)
                      //           : 0;
                      //       final qty = (item['quantity'] ?? 1) is num ? (item['quantity'] as num).toInt() : int.tryParse(item['quantity'].toString()) ?? 1;
                      //       return sum + (price * qty);
                      //     })} Coin',
                      //     style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 16),
                      //   ),
                      // ),
                    ],
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
  
  // Voucher variables
  final TextEditingController _voucherController = TextEditingController();
  Map<String, dynamic>? appliedVoucher;
  bool isApplyingVoucher = false;
  double originalTotal = 0.0;
  double discountAmount = 0.0;
  double finalTotal = 0.0;

  @override
  void initState() {
    super.initState();
    // Initialize totals from widget cart items
    originalTotal = widget.totalPrice;
    finalTotal = originalTotal;
    // Load user addresses
    _loadAddresses();
  }

  @override
  void dispose() {
    _voucherController.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    final userData = await AuthService.getUserData();
    final userId = userData?['id'];
    if (userId == null) return;
    
    print('=== DEBUG ADDRESSES ===');
    print('Loading addresses for user ID: $userId');
    
    try {
      final result = await AuthService.getUserAddresses(userId: userId);
      print('Address result: $result');
      
      if (result['success'] == true && result['data'] is List) {
        if (mounted) {
          setState(() {
            addresses = result['data'];
            print('Loaded ${addresses.length} addresses');
            
            // Auto-select default address if available
            if (addresses.isNotEmpty) {
              final defaultAddress = addresses.firstWhere(
                (addr) => addr['is_default'] == 1,
                orElse: () => addresses.first,
              );
              selectedAddressId = defaultAddress['id'];
              print('Selected address ID: $selectedAddressId');
            } else {
              print('No addresses found');
            }
          });
        }
      } else {
        print('Failed to load addresses: ${result['message']}');
      }
    } catch (e) {
      print('Error loading addresses: $e');
    }
  }

  Future<void> _applyVoucher() async {
    final voucherCode = _voucherController.text.trim();
    if (voucherCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập mã voucher'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() { isApplyingVoucher = true; });

    try {
      // Lấy danh sách product IDs từ cart items
      final productIds = <int>[];
      print('=== DEBUG VOUCHER APPLICATION ===');
      print('Cart Items Count: ${widget.cartItems.length}');
      
      for (var item in widget.cartItems) {
        print('Processing item: ${item['type']}');
        
        if (item['type'] == 'combination') {
          // Nếu là combo, lấy product IDs từ combination_items
          if (item['combination_items'] != null && item['combination_items'] is List) {
            print('Combination items: ${item['combination_items']}');
            for (var comboItem in item['combination_items']) {
              if (comboItem['product_id'] != null) {
                productIds.add(comboItem['product_id']);
                print('Added product ID from combo: ${comboItem['product_id']}');
              }
            }
          }
        } else {
          // Nếu là sản phẩm đơn lẻ
          if (item['product_id'] != null) {
            productIds.add(item['product_id']);
            print('Added product ID from single item: ${item['product_id']}');
          }
        }
      }

      print('Final Product IDs: $productIds');

      if (productIds.isEmpty) {
        throw Exception('Không có sản phẩm hợp lệ để áp dụng voucher');
      }

      print('Calling VoucherService.validateVoucher...');
      final result = await VoucherService.validateVoucher(voucherCode, productIds);

      setState(() { isApplyingVoucher = false; });

      // Tạo voucher object từ result
      final voucher = {
        'voucher_id': result.voucherId,
        'voucher_code': result.voucherCode,
        'discount_amount': result.discountAmount,
        'voucher_type': result.voucherType,
        'category_filter': result.categoryFilter,
      };
      
      setState(() {
        appliedVoucher = voucher;
        discountAmount = result.totalDiscount;
        finalTotal = originalTotal - result.totalDiscount;
      });

      // Debug: In ra thông tin voucher
      print('=== DEBUG VOUCHER ===');
      print('Original Total: $originalTotal');
      print('Discount Amount: $discountAmount');
      print('Final Total: $finalTotal');
      print('Applied Voucher: $appliedVoucher');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Áp dụng voucher thành công! Giảm ${result.formattedTotalDiscount}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() { isApplyingVoucher = false; });
      
      print('Voucher Application Error: $e');
      
      // Xử lý các loại lỗi khác nhau
      String errorMessage = 'Lỗi áp dụng voucher';
      if (e.toString().contains('Voucher not found')) {
        errorMessage = '❌ Mã voucher không tồn tại';
      } else if (e.toString().contains('not valid at this time')) {
        errorMessage = '❌ Voucher không còn hiệu lực';
      } else if (e.toString().contains('fully used')) {
        errorMessage = '❌ Voucher đã hết số lượng';
      } else if (e.toString().contains('not applicable')) {
        errorMessage = '❌ Voucher không áp dụng cho sản phẩm này';
      } else if (e.toString().contains('Network error')) {
        errorMessage = '❌ Lỗi kết nối mạng';
      } else if (e.toString().contains('Không có sản phẩm hợp lệ')) {
        errorMessage = '❌ Không có sản phẩm hợp lệ để áp dụng voucher';
      } else if (e.toString().contains('Method not allowed')) {
        errorMessage = '❌ Lỗi server: Method not allowed';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeVoucher() {
    setState(() {
      appliedVoucher = null;
      discountAmount = 0.0;
      finalTotal = originalTotal;
      _voucherController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🗑️ Đã xóa voucher'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _placeOrder() async {
    final userData = await AuthService.getUserData();
    final userId = userData?['id'];
    
    print('=== DEBUG ORDER REQUEST ===');
    print('User Data: $userData');
    print('User ID: $userId');
    print('Selected Address ID: $selectedAddressId');
    print('Cart Items Count: ${widget.cartItems.length}');
    
    if (userId == null) {
      print('ERROR: User ID is null');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Lỗi: Không tìm thấy thông tin người dùng'), backgroundColor: Colors.red),
      );
      return;
    }
    
    if (selectedAddressId == null) {
      print('ERROR: Address ID is null');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Lỗi: Vui lòng chọn địa chỉ giao hàng'), backgroundColor: Colors.red),
      );
      return;
    }
    
    if (widget.cartItems.isEmpty) {
      print('ERROR: Cart items is empty');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Lỗi: Giỏ hàng trống'), backgroundColor: Colors.red),
      );
      return;
    }
    
    setState(() { isLoading = true; });
    
    try {
      // Debug: Log order data
      print('Payment Method: $paymentMethod');
      print('Applied Voucher: $appliedVoucher');
      print('Discount Amount: $discountAmount');
      
      // Prepare voucher data if applied
      Map<String, dynamic>? voucherData;
      if (appliedVoucher != null) {
        voucherData = {
          'voucher_id': appliedVoucher!['voucher_id'],
          'voucher_code': appliedVoucher!['voucher_code'],
          'discount_amount': discountAmount,
        };
        print('Voucher Data: $voucherData');
      }
      
      print('Calling placeOrderWithCombinations...');
      final result = await AuthService.placeOrderWithCombinations(
        userId: userId,
        addressId: selectedAddressId!,
        paymentMethod: paymentMethod,
        cartItems: widget.cartItems.cast<Map<String, dynamic>>(),
        voucherData: voucherData,
      );
      
      print('Order Result: $result');
      
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
      print('Order Error: $e');
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
                    
                    if (item['type'] == 'combination') {
                      // Xác định hình ảnh cho combo trong dialog
                      final comboImage = item['combination_image'] ?? item['image_url'] ?? '';
                      
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
                                child: comboImage.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: CachedNetworkImage(
                                          imageUrl: 'http://127.0.0.1/EcommerceClothingApp/API/uploads/serve_image.php?file=$comboImage',
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
                                      item['combination_name'] ?? 'Combo',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'SL: ${item['quantity']} x ${item['combination_price']} VNĐ',
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
                    } else {
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
                    }
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
              
              // Voucher section
              const Text('🎫 Mã giảm giá:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              if (appliedVoucher != null) ...[
                // Applied voucher display
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Voucher: ${appliedVoucher!['voucher_code']}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                            Text(
                              'Giảm ${discountAmount.toStringAsFixed(0)} VNĐ',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _removeVoucher,
                        icon: Icon(Icons.close, color: Colors.green.shade700),
                        iconSize: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ] else ...[
                // Voucher input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _voucherController,
                        decoration: const InputDecoration(
                          hintText: 'Nhập mã voucher',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: isApplyingVoucher ? null : _applyVoucher,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                      ),
                      child: isApplyingVoucher
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Áp dụng'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              
              // Payment method
              const Text('Phương thức thanh toán:'),
              DropdownButton<String>(
                value: paymentMethod,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'COD', child: Text('Thanh toán khi nhận hàng (COD)')),
                  DropdownMenuItem(value: 'VNPAY', child: Text('VNPAY')),
                  DropdownMenuItem(value: 'BACoin', child: Text('Thanh toán bằng BACoin')),
                ],
                onChanged: (v) => setState(() => paymentMethod = v ?? 'COD'),
              ),
              
              const SizedBox(height: 12),
              
              // Total with voucher
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng tiền gốc:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${originalTotal.toStringAsFixed(0)} VNĐ', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (appliedVoucher != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Giảm giá (${appliedVoucher!['voucher_code']}):', style: TextStyle(color: Colors.green.shade700)),
                        Text('-${discountAmount.toStringAsFixed(0)} VNĐ', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng tiền thanh toán:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${finalTotal.toStringAsFixed(0)} VNĐ <=> BACoin', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 16)),
                    ],
                  ),
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