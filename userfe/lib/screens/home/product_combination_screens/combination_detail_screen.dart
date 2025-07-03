import 'package:flutter/material.dart';
import '../../../models/product_combination_model.dart';
import '../../../services/product_combination_service.dart';
import '../../../services/auth_service.dart';

class CombinationDetailScreen extends StatefulWidget {
  final ProductCombination combination;
  final VoidCallback? onCartUpdated;
  const CombinationDetailScreen({Key? key, required this.combination, this.onCartUpdated}) : super(key: key);

  @override
  State<CombinationDetailScreen> createState() => _CombinationDetailScreenState();
}

class _CombinationDetailScreenState extends State<CombinationDetailScreen> {
  int quantity = 1;
  int currentImage = 0;
  final ProductCombinationService _service = ProductCombinationService();

  // Map productId -> List<VariantModel>
  final Map<int, List<VariantModel>> _productVariants = {};
  // Map itemId -> selected variantId
  final Map<int, int?> _selectedVariantIds = {};
  // Map itemId -> selected VariantModel
  final Map<int, VariantModel?> _selectedVariants = {};
  bool _loadingVariants = true;

  @override
  void initState() {
    super.initState();
    _fetchAllVariants();
  }

  Future<void> _fetchAllVariants() async {
    setState(() { _loadingVariants = true; });
    for (final item in widget.combination.items) {
      final variants = await _service.getVariantsByProduct(item.productId);
      _productVariants[item.productId] = variants;
      // Chọn mặc định: nếu item.variantId có trong variants thì chọn, không thì chọn variant đầu tiên
      VariantModel? selected;
      if (item.variantId != null) {
        if (variants.isNotEmpty) {
          selected = variants.firstWhere(
            (v) => v.variantId == item.variantId,
            orElse: () => variants[0],
          );
        } else {
          selected = null;
        }
      } else {
        selected = variants.isNotEmpty ? variants[0] : null;
      }
      _selectedVariantIds[item.id] = selected?.variantId;
      _selectedVariants[item.id] = selected;
    }
    setState(() { _loadingVariants = false; });
  }

  String buildImageUrl(String fileName) {
    // Nếu chạy trên thiết bị/emulator, thay 127.0.0.1 bằng IP LAN của máy chủ
    return 'http://127.0.0.1/EcommerceClothingApp/API/uploads/serve_image.php?file=$fileName';
  }

  List<String> get imageUrls {
    List<String> images = [];
    for (final item in widget.combination.items) {
      final variant = _selectedVariants[item.id];
      if (variant != null && variant.imageUrl.isNotEmpty) {
        images.add(buildImageUrl(variant.imageUrl));
      } else if (item.productImage != null && item.productImage!.isNotEmpty) {
        images.add(buildImageUrl(item.productImage!));
      }
    }
    return images;
  }

  double get totalPrice {
    double sum = 0;
    for (final item in widget.combination.items) {
      final variant = _selectedVariants[item.id];
      sum += ((variant?.price ?? item.priceInCombination ?? 0) * item.quantity);
    }
    return sum * quantity;
  }

  void showImageDialog(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(
          child: Image.network(url),
        ),
      ),
    );
  }

  // Thêm method để thêm combination vào giỏ hàng
  Future<void> _addCombinationToCart() async {
    // 1. Kiểm tra tất cả items đã có variant được chọn chưa
    for (final item in widget.combination.items) {
      if (_selectedVariants[item.id] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Vui lòng chọn đầy đủ các thuộc tính cho tất cả sản phẩm trong combo.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
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

    // 3. Chuẩn bị danh sách items cho API
    final items = widget.combination.items.map((item) {
      final variant = _selectedVariants[item.id]!;
      return {
        'product_id': item.productId,
        'variant_id': variant.variantId,
        'quantity': item.quantity,
      };
    }).toList();

    // 4. Gọi API addCombinationToCart
    final result = await _service.addCombinationToCart(
      userId: userId,
      combinationId: widget.combination.id,
      quantity: quantity,
      items: items,
    );

    // 5. Phản hồi kết quả
    if (result['success'] == true) {
      // Gọi callback để cập nhật cart count
      widget.onCartUpdated?.call();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              const Text('🛒 Combo đã được thêm vào giỏ hàng!'),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Đóng combination detail screen
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
          content: Text(result['message'] ?? '❌ Không thể thêm combo vào giỏ hàng.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final combination = widget.combination;
    return Scaffold(
      appBar: AppBar(title: Text(combination.name)),
      body: _loadingVariants
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Carousel ảnh
                  if (imageUrls.isNotEmpty)
                    Column(
                      children: [
                        SizedBox(
                          height: 220,
                          child: PageView.builder(
                            itemCount: imageUrls.length,
                            onPageChanged: (i) => setState(() => currentImage = i),
                            itemBuilder: (context, i) => GestureDetector(
                              onTap: () => showImageDialog(imageUrls[i]),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(imageUrls[i], fit: BoxFit.cover),
                              ),
                            ),
                          ),
                        ),
                        if (imageUrls.length > 1)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              imageUrls.length,
                              (i) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: currentImage == i ? Colors.blue : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      combination.name,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (combination.description != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        combination.description!,
                        style: const TextStyle(fontSize: 15, color: Colors.black87),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('Giá combo: ', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('${totalPrice.toStringAsFixed(0)}đ', style: const TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (combination.categories.isNotEmpty)
                    Text('Danh mục: ' + combination.categories.join(', '), style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 20),
                  const Text('Sản phẩm trong combo:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ...combination.items.map((item) {
                    final variants = _productVariants[item.productId] ?? [];
                    final selectedVariantId = _selectedVariantIds[item.id];
                    final selectedVariant = _selectedVariants[item.id];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ExpansionTile(
                        leading: selectedVariant != null && selectedVariant.imageUrl.isNotEmpty
                            ? Image.network(buildImageUrl(selectedVariant.imageUrl), width: 50, height: 50, fit: BoxFit.cover)
                            : (item.productImage != null && item.productImage!.isNotEmpty)
                                ? Image.network(buildImageUrl(item.productImage!), width: 50, height: 50, fit: BoxFit.cover)
                                : const Icon(Icons.image, size: 50),
                        title: Text(item.productName ?? ''),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item.productCategory != null)
                              Text('Danh mục: ' + item.productCategory!),
                            if (selectedVariant != null && selectedVariant.sku.isNotEmpty)
                              Text('SKU: ' + selectedVariant.sku),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (variants.isNotEmpty)
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      for (final variant in variants)
                                        ChoiceChip(
                                          label: Text(variant.attributeValues.map((av) => av.value).join(' - ')),
                                          selected: selectedVariantId == variant.variantId,
                                          onSelected: (selected) {
                                            if (selected) {
                                              setState(() {
                                                _selectedVariantIds[item.id] = variant.variantId;
                                                _selectedVariants[item.id] = variant;
                                              });
                                            }
                                          },
                                        ),
                                    ],
                                  ),
                                if (selectedVariant != null)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Giá: ${selectedVariant.price.toStringAsFixed(0)}đ'),
                                      Text('Kho: ${selectedVariant.stock}'),
                                    ],
                                  ),
                                if (item.quantity > 1)
                                  Text('Số lượng trong combo: ${item.quantity}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 80), // Để tránh che bởi bottom bar
                ],
              ),
            ),
      bottomNavigationBar: _loadingVariants
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tổng tiền:', style: TextStyle(fontSize: 13)),
                        Text(
                          '${totalPrice.toStringAsFixed(0)}đ',
                          style: const TextStyle(fontSize: 20, color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: quantity > 1 ? () => setState(() => quantity--) : null,
                      ),
                      Text('$quantity', style: const TextStyle(fontSize: 18)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setState(() => quantity++),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.shopping_cart),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _addCombinationToCart,
                    label: const Text('Thêm vào giỏ'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      // TODO: Xử lý mua ngay
                    },
                    child: const Text('Mua ngay'),
                  ),
                ],
              ),
            ),
    );
  }
} 