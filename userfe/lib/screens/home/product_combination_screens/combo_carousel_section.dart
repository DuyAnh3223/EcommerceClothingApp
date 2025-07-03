import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import '../../../models/product_combination_model.dart';
import '../../../services/product_combination_service.dart';
import 'combination_detail_screen.dart';

class ComboCarouselSection extends StatefulWidget {
  final VoidCallback? onCartUpdated;
  const ComboCarouselSection({Key? key, this.onCartUpdated}) : super(key: key);

  @override
  State<ComboCarouselSection> createState() => _ComboCarouselSectionState();
}

class _ComboCarouselSectionState extends State<ComboCarouselSection> {
  late Future<List<ProductCombination>> _futureCombos;
  final PageController _pageController = PageController(viewportFraction: 0.33);
  Timer? _autoScrollTimer;
  int _currentPage = 0;

  String buildImageUrl(String fileName) {
    // Nếu chạy trên thiết bị/emulator, thay 127.0.0.1 bằng IP LAN của máy chủ
    return 'http://127.0.0.1/EcommerceClothingApp/API/uploads/serve_image.php?file=$fileName';
  }

  String? getCombinationImageUrl(ProductCombination combination) {
    // Ưu tiên hình ảnh tổ hợp nếu có
    if (combination.imageUrl != null && combination.imageUrl!.isNotEmpty) {
      return buildImageUrl(combination.imageUrl!);
    }
    
    // Nếu không có hình ảnh tổ hợp, lấy hình ảnh của sản phẩm đầu tiên
    if (combination.items != null && combination.items.isNotEmpty) {
      final firstItem = combination.items.first;
      
      // Ưu tiên hình ảnh variant nếu có
      if (firstItem.variantImage != null && firstItem.variantImage!.isNotEmpty) {
        return buildImageUrl(firstItem.variantImage!);
      }
      
      // Fallback về hình ảnh sản phẩm
      if (firstItem.productImage != null && firstItem.productImage!.isNotEmpty) {
        return buildImageUrl(firstItem.productImage!);
      }
    }
    
    return null;
  }

  void showImageDialog(BuildContext context, String imageUrl, String title) {
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
                title: Text('Hình ảnh: $title'),
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
                  imageUrl: imageUrl,
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

  @override
  void initState() {
    super.initState();
    _futureCombos = ProductCombinationService().getCombinations();
  }

  void _startAutoScroll(int itemCount) {
    _autoScrollTimer?.cancel();
    if (itemCount <= 1) return;
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        _currentPage = (_currentPage + 1) % itemCount;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ProductCombination>>(
      future: _futureCombos,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 220, child: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasError) {
          return SizedBox(height: 220, child: Center(child: Text('Lỗi: ${snapshot.error}')));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(height: 220, child: Center(child: Text('Không có combo nào.')));
        }
        final combos = snapshot.data!;
        _startAutoScroll(combos.length);
        return SizedBox(
          height: 300,
          child: PageView.builder(
            controller: _pageController,
            itemCount: combos.length,
            itemBuilder: (context, index) {
              final combo = combos[index];
              // Tính khoảng giá
              double minPrice = combo.items.isNotEmpty
                  ? combo.items.map((e) => e.priceInCombination ?? 0).reduce((a, b) => a < b ? a : b)
                  : 0;
              double maxPrice = combo.items.isNotEmpty
                  ? combo.items.map((e) => e.priceInCombination ?? 0).reduce((a, b) => a > b ? a : b)
                  : 0;
              double? discountPrice = combo.discountPrice;
              double? originalPrice = combo.originalPrice;
              double? price ;
              // Nếu tồn tại cả discountPrice và originalPrice, ưu tiên discountPrice
              if (discountPrice != null && discountPrice > 0) {
                price = discountPrice;
              } else if (originalPrice != null && originalPrice > 0) {
                price = originalPrice;
              } else {
                price = 0;
              }
              // Phần trăm giảm
              double percent = (minPrice > 0 && discountPrice != null)
                  ? ((minPrice - discountPrice) / minPrice * 100).clamp(0, 100)
                  : 0;
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = ((_pageController.page ?? _currentPage).toDouble()) - index;
                    value = (1 - (value.abs() * 0.2)).clamp(0.8, 1.0);
                  }
                  return Center(
                    child: SizedBox(
                      height: Curves.easeOut.transform(value) * 280,
                      width: Curves.easeOut.transform(value) * 220,
                      child: child,
                    ),
                  );
                },
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CombinationDetailScreen(
                          combination: combo,
                          onCartUpdated: widget.onCartUpdated,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 6,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Ảnh combo
                          GestureDetector(
                            onTap: () {
                              final imageUrl = getCombinationImageUrl(combo);
                              if (imageUrl != null) {
                                showImageDialog(context, imageUrl, combo.name);
                              }
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                children: [
                                  getCombinationImageUrl(combo) != null
                                      ? CachedNetworkImage(
                                          imageUrl: getCombinationImageUrl(combo)!,
                                          height: 120,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(
                                            height: 120,
                                            width: double.infinity,
                                            color: Colors.grey.shade200,
                                            child: const Center(
                                              child: CircularProgressIndicator(),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) => Container(
                                            height: 120,
                                            width: double.infinity,
                                            color: Colors.grey.shade200,
                                            child: const Icon(Icons.image, size: 60, color: Colors.grey),
                                          ),
                                        )
                                      : Container(
                                          height: 120,
                                          width: double.infinity,
                                          color: Colors.grey.shade200,
                                          child: const Icon(Icons.image, size: 60, color: Colors.grey),
                                        ),
                                  // Icon zoom khi có hình ảnh
                                  if (getCombinationImageUrl(combo) != null)
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Icon(
                                          Icons.zoom_in,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            combo.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          // // Giá khoảng
                          // Text(
                          //   'Giá: ${minPrice.toStringAsFixed(0)}K ~ ${maxPrice.toStringAsFixed(0)}K',
                          //   style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15),
                          // ),
                          // Giá ưu đãi
                          
                             Text(
                            'Giá khuyến mãi: ${price.toStringAsFixed(0)}K',
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          
                          // Phần trăm giảm
                          if (percent > 0)
                            Row(
                              children: [
                                const Icon(Icons.local_offer, color: Colors.orange, size: 18),
                                const SizedBox(width: 4),
                                Text('-${percent.toStringAsFixed(0)}%', style: const TextStyle(color: Colors.orange, fontSize: 15)),
                              ],
                            ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
} 