import 'dart:math' as console;

import 'package:flutter/material.dart';
import 'package:userfe/services/auth_service.dart';
import 'package:userfe/screens/auth/login_screen.dart';
import 'package:userfe/screens/home/cart_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> products = [];
  bool isLoading = true;
  Map<String, dynamic>? currentUser;
  int cartCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadProducts();
    _loadCartCount();
  }

  Future<void> _loadUserData() async {
    final userData = await AuthService.getUserData();
    setState(() {
      currentUser = userData;
    });
  }

  Future<void> _loadProducts() async {
    try {
      final result = await AuthService.getProducts();
      if (result['success'] == true) {
        setState(() {
          products = List<Map<String, dynamic>>.from(result['data'] ?? []);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Lỗi tải sản phẩm'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadCartCount() async {
    final userData = await AuthService.getUserData();
    final userId = userData?['id'];
    if (userId == null) return;
    final result = await AuthService.getCart(userId: userId);
    if (result['success'] == true && result['data'] is List) {
      setState(() {
        cartCount = (result['data'] as List).fold<int>(0, (sum, item) => (sum + (item['quantity'] ?? 0)).toInt());
      });
    }
  }

  void _updateCartCount() {
    _loadCartCount();
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Đăng xuất'),
          content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                // Hiển thị loading
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đang đăng xuất...'),
                    backgroundColor: Colors.orange,
                  ),
                );

                try {
                  // Gọi logout từ server (optional)
                  await AuthService.serverLogout();
                  
                  // Gọi logout local
                  await AuthService.logout();

                  // Hiển thị thông báo thành công
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã đăng xuất thành công'),
                        backgroundColor: Colors.green,
                      ),
                    );

                    // Chuyển về login screen
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  // Nếu server logout thất bại, vẫn logout local
                  await AuthService.logout();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã đăng xuất thành công'),
                        backgroundColor: Colors.green,
                      ),
                    );

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                }
              },
              child: const Text('Đăng xuất'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartScreen()),
                  );
                },
              ),
              if (cartCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '$cartCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Đăng xuất',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.person),
            onSelected: (value) {
              if (value == 'profile') {
                // Navigate to profile
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tính năng hồ sơ đang phát triển'),
                  ),
                );
              } else if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person),
                    const SizedBox(width: 8),
                    Text('Hồ sơ: ${currentUser?['username'] ?? 'User'}'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Đăng xuất'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadProducts,
              child: Column(
                children: [
                  // Welcome Message
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.waving_hand, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          'Chào mừng ${currentUser?['username'] ?? 'bạn'}!',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Search Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm sản phẩm...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Products Grid
                  Expanded(
                    child: products.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inventory_2,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Không có sản phẩm nào',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              final product = products[index];
                              final variants = product['variants'] as List? ?? [];
                              final firstVariant = variants.isNotEmpty ? variants[0] : null;
                              return Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Product Image
                                    Expanded(
                                      flex: 3,
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(12),
                                          ),
                                          color: Colors.grey.shade200,
                                        ),
                                        child: (firstVariant != null && firstVariant['image_url'] != null && firstVariant['image_url'] != '')
                                            ? ClipRRect(
                                                borderRadius: const BorderRadius.vertical(
                                                  top: Radius.circular(12),
                                                ),
                                                child: Image.network(
                                                  firstVariant['image_url'],
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return const Icon(
                                                      Icons.image,
                                                      size: 50,
                                                      color: Colors.grey,
                                                    );
                                                  },
                                                ),
                                              )
                                            : const Icon(
                                                Icons.image,
                                                size: 50,
                                                color: Colors.grey,
                                              ),
                                      ),
                                    ),
                                    
                                    // Product Info
                                    Expanded(
                                      flex: 2,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product['name'] ?? 'Tên sản phẩm',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              (firstVariant != null && firstVariant['price'] != null)
                                                  ? 'Giá từ: ${firstVariant['price']} VNĐ'
                                                  : '0 VNĐ',
                                              style: TextStyle(
                                                color: Colors.orange.shade700,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) => ProductDetailDialog(product: product, onCartChanged: _updateCartCount),
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.orange.shade700,
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                                child: const Text(
                                                  'Xem chi tiết',
                                                  style: TextStyle(fontSize: 12),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

class ProductDetailDialog extends StatefulWidget {
  final Map<String, dynamic> product;
  final VoidCallback? onCartChanged;
  const ProductDetailDialog({Key? key, required this.product, this.onCartChanged}) : super(key: key);

  @override
  State<ProductDetailDialog> createState() => _ProductDetailDialogState();
}

class _ProductDetailDialogState extends State<ProductDetailDialog> {
  late List variants;
  String? selectedColor;
  String? selectedSize;
  String? selectedBrand;
  Map<String, dynamic>? selectedVariant;

  @override
  void initState() {
    super.initState();
    variants = widget.product['variants'] as List? ?? [];
    // Lấy tất cả giá trị thuộc tính
    final colors = <String>{};
    final sizes = <String>{};
    final brands = <String>{};
    for (final v in variants) {
      for (final attr in v['attribute_values'] as List) {
        if (attr['attribute_name'] == 'color') colors.add(attr['value']);
        if (attr['attribute_name'] == 'size') sizes.add(attr['value']);
        if (attr['attribute_name'] == 'brand') brands.add(attr['value']);
      }
    }
    selectedColor = colors.isNotEmpty ? colors.first : null;
    selectedSize = sizes.isNotEmpty ? sizes.first : null;
    selectedBrand = brands.isNotEmpty ? brands.first : null;
    _updateSelectedVariant();
  }

  void _updateSelectedVariant() {
    setState(() {
      selectedVariant = variants.firstWhereOrNull((v) {
        final attrs = v['attribute_values'] as List;
        final color = attrs.firstWhereOrNull((a) => a['attribute_name'] == 'color')?['value'];
        final size = attrs.firstWhereOrNull((a) => a['attribute_name'] == 'size')?['value'];
        final brand = attrs.firstWhereOrNull((a) => a['attribute_name'] == 'brand')?['value'];
        return color == selectedColor && size == selectedSize && brand == selectedBrand;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Lấy lại tất cả giá trị thuộc tính
    final colors = <String>{};
    final sizes = <String>{};
    final brands = <String>{};
    for (final v in variants) {
      for (final attr in v['attribute_values'] as List) {
        if (attr['attribute_name'] == 'color') colors.add(attr['value']);
        if (attr['attribute_name'] == 'size') sizes.add(attr['value']);
        if (attr['attribute_name'] == 'brand') brands.add(attr['value']);
      }
    }
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ảnh lớn
              Center(
                child: (selectedVariant != null && selectedVariant!['image_url'] != null && selectedVariant!['image_url'] != '')
                    ? Image.network(selectedVariant!['image_url'], height: 180)
                    : const Icon(Icons.image, size: 100, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Text(widget.product['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              // Color
              if (colors.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: colors.map((color) => ChoiceChip(
                    label: Text(color),
                    selected: selectedColor == color,
                    onSelected: (_) {
                      setState(() {
                        selectedColor = color;
                        _updateSelectedVariant();
                      });
                    },
                  )).toList(),
                ),
              const SizedBox(height: 8),
              // Size
              if (sizes.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: sizes.map((size) => ChoiceChip(
                    label: Text(size),
                    selected: selectedSize == size,
                    onSelected: (_) {
                      setState(() {
                        selectedSize = size;
                        _updateSelectedVariant();
                      });
                    },
                  )).toList(),
                ),
              const SizedBox(height: 8),
              // Brand
              if (brands.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: brands.map((brand) => ChoiceChip(
                    label: Text(brand),
                    selected: selectedBrand == brand,
                    onSelected: (_) {
                      setState(() {
                        selectedBrand = brand;
                        _updateSelectedVariant();
                      });
                    },
                  )).toList(),
                ),
              const SizedBox(height: 12),
              // Giá và tồn kho
              if (selectedVariant != null)
                Row(
                  children: [
                    Text('Giá: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('${selectedVariant!['price']} VNĐ', style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 24),
                    Text('Tồn kho: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('${selectedVariant!['stock']}', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              if (selectedVariant == null)
                const Text('Không có variant phù hợp', style: TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: selectedVariant == null ? null : () async {
                        // 1. Kiểm tra đủ thuộc tính
                        if (selectedColor == null || selectedSize == null || selectedBrand == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('⚠️ Vui lòng chọn đầy đủ các thuộc tính trước khi thêm vào giỏ hàng.'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }
                        if (selectedVariant == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('❌ Không có variant phù hợp!'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        // 2. Lấy user_id
                        final userData = await AuthService.getUserData();
                        final userId = userData?['id'];
                        if (userId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Bạn cần đăng nhập lại!'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        // 3. Gọi API addToCart
                        final result = await AuthService.addToCart(
                          userId: userId,
                          productId: widget.product['id'],
                          variantId: selectedVariant!['variant_id'],
                          quantity: 1,
                        );
                        // 4. Đóng dialog và phản hồi
                        Navigator.of(context).pop();
                        if (result['success'] == true) {
                          if (widget.onCartChanged != null) widget.onCartChanged!();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.white),
                                  SizedBox(width: 8),
                                  const Text('🛒 Sản phẩm đã được thêm vào giỏ hàng!'),
                                  Spacer(),
                                  TextButton(
                                    onPressed: () {
                                      // TODO: Chuyển sang trang giỏ hàng
                                    },
                                    child: const Text('Xem giỏ hàng', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result['message'] ?? '❌ Không thể thêm vào giỏ hàng.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Thêm vào giỏ hàng'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: selectedVariant == null ? null : () {
                        showDialog(
                          context: context,
                          builder: (context) => OrderConfirmDialog(
                            product: widget.product,
                            variant: selectedVariant!,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Mua ngay'),
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

class OrderConfirmDialog extends StatefulWidget {
  final Map<String, dynamic> product;
  final Map<String, dynamic> variant;
  final int initialQuantity;
  const OrderConfirmDialog({Key? key, required this.product, required this.variant, this.initialQuantity = 1}) : super(key: key);

  @override
  State<OrderConfirmDialog> createState() => _OrderConfirmDialogState();
}

class _OrderConfirmDialogState extends State<OrderConfirmDialog> {
  List addresses = [];
  int? selectedAddressId;
  String paymentMethod = 'COD';
  int quantity = 1;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    quantity = widget.initialQuantity;
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
    final result = await AuthService.placeOrder(
      userId: userId,
      productId: widget.product['id'],
      variantId: widget.variant['variant_id'],
      quantity: quantity,
      addressId: selectedAddressId!,
      paymentMethod: paymentMethod,
    );
    setState(() { isLoading = false; });
    Navigator.of(context).pop();
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              const Text('🎉 Đặt hàng thành công!'),
              Spacer(),
              TextButton(
                onPressed: () {
                  // TODO: Xem đơn hàng
                },
                child: const Text('Xem đơn hàng', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? '❌ Đặt hàng thất bại.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final attrs = (widget.variant['attribute_values'] as List?)?.map((attr) => '${attr['attribute_name']}: ${attr['value']}').join(' / ') ?? '';
    final price = widget.variant['price'] ?? 0;
    final stock = widget.variant['stock'] ?? 0;
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
              Row(
                children: [
                  widget.variant['image_url'] != null && widget.variant['image_url'] != ''
                      ? Image.network(widget.variant['image_url'], width: 80, height: 80, fit: BoxFit.cover)
                      : const Icon(Icons.image, size: 80, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.product['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(attrs, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text('Giá: $price VNĐ'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Số lượng:'),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: quantity > 1 ? () => setState(() => quantity--) : null,
                  ),
                  Text('$quantity', style: const TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: quantity < stock ? () => setState(() => quantity++) : null,
                  ),
                  const Spacer(),
                  Text('Tồn kho: $stock'),
                ],
              ),
              const SizedBox(height: 8),
              // Địa chỉ
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
              // Phương thức thanh toán
              const Text('Phương thức thanh toán:'),
              DropdownButton<String>(
                value: paymentMethod,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'COD', child: Text('Thanh toán khi nhận hàng (COD)')),
                  DropdownMenuItem(value: 'Bank', child: Text('Chuyển khoản ngân hàng')),
                  DropdownMenuItem(value: 'Momo', child: Text('Ví Momo')),
                  DropdownMenuItem(value: 'VNPAY', child: Text('VNPAY')),
                ],
                onChanged: (v) => setState(() => paymentMethod = v ?? 'COD'),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tổng tiền:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('${(price * quantity).toStringAsFixed(0)} VNĐ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('⬅️ Quay lại'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (isLoading || addresses.isEmpty) ? null : _placeOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                      ),
                      child: isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('🧾 Đặt hàng ngay'),
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

extension IterableExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
} 