import 'package:flutter/material.dart';
import '../services/voucher_service.dart';

class VoucherInputWidget extends StatefulWidget {
  final List<int> productIds;
  final Function(VoucherValidationResult) onVoucherApplied;
  final Function() onVoucherRemoved;

  const VoucherInputWidget({
    Key? key,
    required this.productIds,
    required this.onVoucherApplied,
    required this.onVoucherRemoved,
  }) : super(key: key);

  @override
  State<VoucherInputWidget> createState() => _VoucherInputWidgetState();
}

class _VoucherInputWidgetState extends State<VoucherInputWidget> {
  final TextEditingController _voucherController = TextEditingController();
  VoucherValidationResult? _appliedVoucher;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _voucherController.dispose();
    super.dispose();
  }

  Future<void> _applyVoucher() async {
    final voucherCode = _voucherController.text.trim();
    if (voucherCode.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập mã voucher';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await VoucherService.validateVoucher(voucherCode, widget.productIds);
      setState(() {
        _appliedVoucher = result;
        _isLoading = false;
      });
      widget.onVoucherApplied(result);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Áp dụng voucher thành công! Giảm ${result.formattedTotalDiscount}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeVoucher() {
    setState(() {
      _appliedVoucher = null;
      _voucherController.clear();
      _errorMessage = null;
    });
    widget.onVoucherRemoved();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã xóa voucher'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  'Mã giảm giá',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (_appliedVoucher == null) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _voucherController,
                      decoration: InputDecoration(
                        hintText: 'Nhập mã voucher',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        errorText: _errorMessage,
                        suffixIcon: _isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : null,
                      ),
                      onSubmitted: (_) => _applyVoucher(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _applyVoucher,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Áp dụng'),
                  ),
                ],
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Voucher: ${_appliedVoucher!.voucherCode}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _removeVoucher,
                          icon: const Icon(Icons.close, color: Colors.red),
                          tooltip: 'Xóa voucher',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Giảm giá: ${_appliedVoucher!.formattedTotalDiscount}'),
                    Text('Sản phẩm áp dụng: ${_appliedVoucher!.applicableProducts.length} sản phẩm'),
                    Text('Còn lại: ${_appliedVoucher!.remainingQuantity} lần sử dụng'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 