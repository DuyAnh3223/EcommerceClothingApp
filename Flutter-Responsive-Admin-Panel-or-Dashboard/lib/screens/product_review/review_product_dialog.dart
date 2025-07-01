import 'package:flutter/material.dart';
import '../../models/pending_product_model.dart';
import '../../services/pending_product_service.dart';

class ReviewProductDialog extends StatefulWidget {
  final PendingProduct product;
  final String action;

  const ReviewProductDialog({
    Key? key,
    required this.product,
    required this.action,
  }) : super(key: key);

  @override
  State<ReviewProductDialog> createState() => _ReviewProductDialogState();
}

class _ReviewProductDialogState extends State<ReviewProductDialog> {
  final _reviewNotesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewNotesController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (widget.action == 'reject' && _reviewNotesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập lý do từ chối'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await PendingProductService.reviewProduct(
        productId: widget.product.id,
        action: widget.action,
        reviewNotes: _reviewNotesController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        if (result['success']) {
          Navigator.pop(context, result);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Thao tác thất bại'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isApprove = widget.action == 'approve';
    final title = isApprove ? 'Duyệt sản phẩm' : 'Từ chối sản phẩm';
    final buttonText = isApprove ? 'Duyệt' : 'Từ chối';
    final buttonColor = isApprove ? Colors.green : Colors.red;

    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sản phẩm: ${widget.product.name}'),
          Text('Agency: ${widget.product.agencyName}'),
          const SizedBox(height: 16),
          
          if (!isApprove) ...[
            const Text('Lý do từ chối:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _reviewNotesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Nhập lý do từ chối...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReview,
          style: ElevatedButton.styleFrom(backgroundColor: buttonColor, foregroundColor: Colors.white),
          child: _isSubmitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
              : Text(buttonText),
        ),
      ],
    );
  }
} 