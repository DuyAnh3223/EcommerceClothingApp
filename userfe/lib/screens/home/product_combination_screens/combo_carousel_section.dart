import 'package:flutter/material.dart';
import 'dart:async';
import '../../../models/product_combination_model.dart';
import '../../../services/product_combination_service.dart';
import 'combination_detail_screen.dart';

class ComboCarouselSection extends StatefulWidget {
  const ComboCarouselSection({Key? key}) : super(key: key);

  @override
  State<ComboCarouselSection> createState() => _ComboCarouselSectionState();
}

class _ComboCarouselSectionState extends State<ComboCarouselSection> {
  late Future<List<ProductCombination>> _futureCombos;
  final PageController _pageController = PageController(viewportFraction: 0.33);
  Timer? _autoScrollTimer;
  int _currentPage = 0;

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
                        builder: (_) => CombinationDetailScreen(combination: combo),
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
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: combo.imageUrl != null && combo.imageUrl!.isNotEmpty
                                ? Image.network(
                                    combo.imageUrl!,
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => const Icon(Icons.image, size: 120),
                                  )
                                : const Icon(Icons.image, size: 120),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            combo.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          // Giá khoảng
                          Text(
                            'Giá: ${minPrice.toStringAsFixed(0)}K ~ ${maxPrice.toStringAsFixed(0)}K',
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          // Giá ưu đãi
                          if (discountPrice != null)
                            Text(
                              'Ưu đãi: ${discountPrice.toStringAsFixed(0)}K',
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