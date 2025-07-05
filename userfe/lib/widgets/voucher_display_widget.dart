import 'package:flutter/material.dart';
import '../services/voucher_service.dart';

class VoucherDisplayWidget extends StatefulWidget {
  final int? productId;
  final String? productCategory;

  const VoucherDisplayWidget({
    Key? key,
    this.productId,
    this.productCategory,
  }) : super(key: key);

  @override
  State<VoucherDisplayWidget> createState() => _VoucherDisplayWidgetState();
}

class _VoucherDisplayWidgetState extends State<VoucherDisplayWidget> {
  List<Voucher> _availableVouchers = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  Future<void> _loadVouchers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final vouchers = await VoucherService.getAvailableVouchers();
      final filteredVouchers = vouchers.where((voucher) {
        // Lọc voucher phù hợp với sản phẩm
        if (widget.productId != null) {
          return voucher.isApplicableForProduct(widget.productId!);
        }
        if (widget.productCategory != null) {
          return voucher.isForAllProducts || 
                 (voucher.isForCategoryBased && voucher.categoryFilter == widget.productCategory);
        }
        return true; // Hiển thị tất cả nếu không có filter
      }).toList();

      setState(() {
        _availableVouchers = filteredVouchers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        margin: EdgeInsets.all(8.0),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_errorMessage != null) {
      return Card(
        margin: const EdgeInsets.all(8.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(height: 8),
              Text('Lỗi: $_errorMessage'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadVouchers,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_availableVouchers.isEmpty) {
      return const Card(
        margin: EdgeInsets.all(8.0),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Không có voucher khả dụng cho sản phẩm này',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_offer, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Voucher khả dụng',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._availableVouchers.map((voucher) => _buildVoucherCard(voucher)),
          ],
        ),
      ),
    );
  }

  Widget _buildVoucherCard(Voucher voucher) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: voucher.canUse ? Colors.orange.shade50 : Colors.grey.shade50,
        border: Border.all(
          color: voucher.canUse ? Colors.orange.shade200 : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  voucher.voucherCode,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: voucher.canUse ? Colors.orange.shade800 : Colors.grey,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: voucher.canUse ? Colors.green : Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  voucher.canUse ? 'Có hiệu lực' : 'Hết hiệu lực',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Giảm giá: ${voucher.formattedDiscountAmount}',
            style: TextStyle(
              color: voucher.canUse ? Colors.green.shade700 : Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            'Loại: ${voucher.formattedVoucherType}',
            style: TextStyle(
              color: voucher.canUse ? Colors.black87 : Colors.grey,
            ),
          ),
          if (voucher.isForCategoryBased && voucher.categoryFilter != null)
            Text(
              'Danh mục: ${voucher.categoryFilter}',
              style: TextStyle(
                color: voucher.canUse ? Colors.black87 : Colors.grey,
              ),
            ),
          Text(
            'Hiệu lực: ${voucher.formattedStartDate} - ${voucher.formattedEndDate}',
            style: TextStyle(
              color: voucher.canUse ? Colors.black54 : Colors.grey,
              fontSize: 12,
            ),
          ),
          Text(
            'Số lượng: ${voucher.quantity}',
            style: TextStyle(
              color: voucher.canUse ? Colors.black54 : Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
} 