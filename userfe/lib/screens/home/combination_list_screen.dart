import 'package:flutter/material.dart';
import '../../models/product_combination_model.dart';
import '../../services/product_combination_service.dart';
import '../../screens/home/combination_detail_screen.dart';

class CombinationListScreen extends StatefulWidget {
  const CombinationListScreen({Key? key}) : super(key: key);

  @override
  State<CombinationListScreen> createState() => _CombinationListScreenState();
}

class _CombinationListScreenState extends State<CombinationListScreen> {
  late Future<List<ProductCombination>> _futureCombinations;

  @override
  void initState() {
    super.initState();
    _futureCombinations = ProductCombinationService().getCombinations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Combo Sản phẩm nổi bật'),
      ),
      body: FutureBuilder<List<ProductCombination>>(
        future: _futureCombinations,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Lỗi: \\${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Không có combo nào.'));
          }
          final combos = snapshot.data!;
          return ListView.builder(
            itemCount: combos.length,
            itemBuilder: (context, index) {
              final combo = combos[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  leading: combo.imageUrl != null
                      ? Image.network(combo.imageUrl!, width: 60, height: 60, fit: BoxFit.cover)
                      : const Icon(Icons.image, size: 60),
                  title: Text(combo.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (combo.discountPrice != null)
                        Text('Giá ưu đãi: \\${combo.discountPrice!.toStringAsFixed(0)}đ', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      if (combo.originalPrice != null)
                        Text('Giá gốc: \\${combo.originalPrice!.toStringAsFixed(0)}đ', style: const TextStyle(decoration: TextDecoration.lineThrough)),
                      if (combo.categories.isNotEmpty)
                        Text('Danh mục: ' + combo.categories.join(', '), style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CombinationDetailScreen(combination: combo),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
} 