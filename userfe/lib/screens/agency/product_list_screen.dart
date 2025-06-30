import 'package:flutter/material.dart';
import '../../models/agency_product_model.dart';
import '../../services/agency_service.dart';

class ProductListScreen extends StatefulWidget {
  final List<AgencyProduct> products;
  final VoidCallback onRefresh;

  const ProductListScreen({
    Key? key,
    required this.products,
    required this.onRefresh,
  }) : super(key: key);

  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String _selectedStatus = 'all';
  List<AgencyProduct> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _filterProducts();
  }

  @override
  void didUpdateWidget(ProductListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.products != widget.products) {
      _filterProducts();
    }
  }

  void _filterProducts() {
    setState(() {
      if (_selectedStatus == 'all') {
        _filteredProducts = widget.products;
      } else {
        _filteredProducts = widget.products
            .where((product) => product.status == _selectedStatus)
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter buttons
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'Tất cả'),
                      const SizedBox(width: 8),
                      _buildFilterChip('pending', 'Chờ duyệt'),
                      const SizedBox(width: 8),
                      _buildFilterChip('active', 'Đã duyệt'),
                      const SizedBox(width: 8),
                      _buildFilterChip('rejected', 'Từ chối'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Product list
        Expanded(
          child: _filteredProducts.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, index) {
                    return _buildProductCard(_filteredProducts[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String status, String label) {
    final isSelected = _selectedStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = status;
          _filterProducts();
        });
      },
      selectedColor: Colors.blue.withOpacity(0.2),
      checkmarkColor: Colors.blue,
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;
    
    switch (_selectedStatus) {
      case 'pending':
        message = 'Không có sản phẩm nào đang chờ duyệt';
        icon = Icons.pending;
        break;
      case 'active':
        message = 'Không có sản phẩm nào đã được duyệt';
        icon = Icons.check_circle;
        break;
      case 'rejected':
        message = 'Không có sản phẩm nào bị từ chối';
        icon = Icons.cancel;
        break;
      default:
        message = 'Chưa có sản phẩm nào. Hãy tạo sản phẩm đầu tiên!';
        icon = Icons.inventory;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(AgencyProduct product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: product.mainImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product.mainImage!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image),
                    );
                  },
                ),
              )
            : Container(
                width: 50,
                height: 50,
                color: Colors.grey[300],
                child: const Icon(Icons.image),
              ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.description),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildStatusChip(product.status),
                const SizedBox(width: 8),
                Text(
                  '${product.variants.length} variants',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        children: [
          // Product details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Basic info
                _buildInfoRow('Danh mục:', product.category),
                _buildInfoRow('Giới tính:', product.genderTarget),
                _buildInfoRow('Phí sàn:', '${product.platformFeeRate}%'),
                
                // Approval info
                if (product.approvalStatus != null) ...[
                  const Divider(),
                  _buildInfoRow('Trạng thái duyệt:', product.approvalStatus!),
                  if (product.reviewNotes != null)
                    _buildInfoRow('Ghi chú:', product.reviewNotes!),
                  if (product.reviewerName != null)
                    _buildInfoRow('Người duyệt:', product.reviewerName!),
                ],
                
                // Variants
                const Divider(),
                const Text(
                  'Các biến thể:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...product.variants.map((variant) => _buildVariantCard(variant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        text = 'Chờ duyệt';
        break;
      case 'active':
        color = Colors.green;
        text = 'Đã duyệt';
        break;
      case 'rejected':
        color = Colors.red;
        text = 'Từ chối';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildVariantCard(AgencyProductVariant variant) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SKU: ${variant.sku}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${variant.price.toStringAsFixed(0)} VNĐ',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Tồn kho: ${variant.stock}'),
                const SizedBox(width: 16),
                Text('Trạng thái: ${variant.variantStatus}'),
              ],
            ),
            if (variant.attributes.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Thuộc tính:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: variant.attributes.entries.map((entry) {
                  return Chip(
                    label: Text('${entry.key}: ${entry.value}'),
                    backgroundColor: Colors.blue.withOpacity(0.1),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 