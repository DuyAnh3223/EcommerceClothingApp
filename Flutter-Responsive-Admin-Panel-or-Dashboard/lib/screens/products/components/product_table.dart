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
        DataColumn(label: Text('Hình ảnh')),
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
          DataCell( // Cột hình ảnh
            GestureDetector(
              onTap: () {
                if (product.mainImage != null && product.mainImage!.isNotEmpty) {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.8,
                          maxHeight: MediaQuery.of(context).size.height * 0.8,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppBar(
                              title: Text('Hình ảnh: ${product.name}'),
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
                              child: Image.network(
                                'http://127.0.0.1/EcommerceClothingApp/API/uploads/serve_image.php?file=${product.mainImage!}',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => const Center(
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
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    (product.mainImage != null && product.mainImage!.isNotEmpty)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              'http://127.0.0.1/EcommerceClothingApp/API/uploads/serve_image.php?file=${product.mainImage!}',
                              fit: BoxFit.cover,
                              width: 60,
                              height: 60,
                              errorBuilder: (context, error, stackTrace) => const Icon(
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
                    if (product.mainImage != null && product.mainImage!.isNotEmpty)
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
          ),
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
