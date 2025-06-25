import 'package:flutter/material.dart';
import '../../../models/product_model.dart';
import '../add_edit_product_screen.dart';
import '../product_variant_screen.dart';

class ProductTable extends StatelessWidget {
  final List<Product> products;
  final Function onReload;
  final Function(Product)? onEdit;
  final Function(int)? onDelete;

  const ProductTable({
    Key? key, 
    required this.products, 
    required this.onReload,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DataTable(
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Tên sản phẩm')),
        DataColumn(label: Text('Danh mục')),
        DataColumn(label: Text('Đối tượng')),
        DataColumn(label: Text('Tổng tồn kho')),
        DataColumn(label: Text('Số biến thể')),
        DataColumn(label: Text('Trạng thái')),
        DataColumn(label: Text('Hành động')),
      ],
      rows: products.map((product) {
        return DataRow(cells: [
          DataCell(Text(product.id.toString())), // Cột ID
          DataCell( // Cột tên
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (product.description.isNotEmpty)
                  Text(
                    product.description,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          DataCell(Text(product.category)), // Cột danh mục
          DataCell(Text(product.genderTarget)), // Cột đối tượng
        
          DataCell( // Cột tổng tồn kho
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: product.totalStock > 0 ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                product.totalStock.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
          DataCell( // Cột số biến thể
            Row(
              children: [
                Text(product.variants.length.toString()),
                const SizedBox(width: 4),             
              ],
            ),
          ),
          DataCell( // Cột trạng thái
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: product.hasActiveVariants ? Colors.blue : Colors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                product.hasActiveVariants ? 'Hoạt động' : 'Không hoạt động',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
          DataCell( // Cột hành động      
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    if (onEdit != null) {
                      onEdit!(product);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductVariantScreen(productId: product.id),
                      ),
                    );
                    // Refresh product data when returning from variant management
                    if (result == true) {
                      onReload();
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    if (onDelete != null) {
                      onDelete!(product.id);
                    }
                  },
                ),
              ],
            ),
          ),
        ]);
      }).toList(),
    );
  }
}
