import 'package:flutter/material.dart';
import '../../models/voucher_model.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../constants.dart';

class AddEditVoucherDialog extends StatefulWidget {
  final Voucher? voucher;

  const AddEditVoucherDialog({Key? key, this.voucher}) : super(key: key);

  @override
  State<AddEditVoucherDialog> createState() => _AddEditVoucherDialogState();
}

class _AddEditVoucherDialogState extends State<AddEditVoucherDialog> {
  final _formKey = GlobalKey<FormState>();
  final _voucherCodeController = TextEditingController();
  final _discountAmountController = TextEditingController();
  final _quantityController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  
  String _selectedVoucherType = 'all_products';
  String? _selectedCategory;
  List<Product> _allProducts = [];
  List<int> _selectedProductIds = [];
  bool _isLoadingProducts = false;

  final List<String> _voucherTypes = [
    'all_products',
    'specific_products',
    'category_based'
  ];

  final List<String> _categories = [
    'T-Shirts',
    'Shirts',
    'Pants',
    'Shorts',
    'Jackets & Coats',
    'Hoodies',
    'Loungewear',
    'Underwear'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.voucher != null) {
      _voucherCodeController.text = widget.voucher!.voucherCode;
      _discountAmountController.text = widget.voucher!.discountAmount.toString();
      _quantityController.text = widget.voucher!.quantity.toString();
      _startDate = widget.voucher!.startDate;
      _endDate = widget.voucher!.endDate;
      _selectedVoucherType = widget.voucher!.voucherType;
      _selectedCategory = widget.voucher!.categoryFilter;
      _selectedProductIds = widget.voucher!.associatedProductIds ?? [];
    }
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoadingProducts = true;
    });

    try {
      final products = await ProductService.getProducts();
      setState(() {
        _allProducts = products;
        _isLoadingProducts = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingProducts = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải danh sách sản phẩm: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _voucherCodeController.dispose();
    _discountAmountController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _toggleProductSelection(int productId) {
    setState(() {
      if (_selectedProductIds.contains(productId)) {
        _selectedProductIds.remove(productId);
      } else {
        _selectedProductIds.add(productId);
      }
    });
  }

  String _getVoucherTypeDisplayName(String type) {
    switch (type) {
      case 'all_products':
        return 'Tất cả sản phẩm';
      case 'specific_products':
        return 'Sản phẩm cụ thể';
      case 'category_based':
        return 'Theo danh mục';
      default:
        return type;
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Validate voucher type specific requirements
      if (_selectedVoucherType == 'specific_products' && _selectedProductIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn ít nhất một sản phẩm')),
        );
        return;
      }

      if (_selectedVoucherType == 'category_based' && _selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn danh mục')),
        );
        return;
      }

      final voucher = Voucher(
        id: widget.voucher?.id ?? 0,
        voucherCode: _voucherCodeController.text.trim(),
        discountAmount: double.parse(_discountAmountController.text),
        quantity: int.parse(_quantityController.text),
        startDate: _startDate,
        endDate: _endDate,
        voucherType: _selectedVoucherType,
        categoryFilter: _selectedCategory,
        associatedProductIds: _selectedVoucherType == 'specific_products' ? _selectedProductIds : null,
      );
      Navigator.of(context).pop(voucher);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.voucher == null ? 'Thêm Voucher' : 'Sửa Voucher'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _voucherCodeController,
                decoration: const InputDecoration(
                  labelText: 'Mã Voucher',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập mã voucher';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _discountAmountController,
                decoration: const InputDecoration(
                  labelText: 'Số tiền giảm giá (VNĐ)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập số tiền giảm giá';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Số tiền phải lớn hơn 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Số lượng',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập số lượng';
                  }
                  final quantity = int.tryParse(value);
                  if (quantity == null || quantity <= 0) {
                    return 'Số lượng phải lớn hơn 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Ngày bắt đầu'),
                      subtitle: Text('${_startDate.day}/${_startDate.month}/${_startDate.year}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: _selectStartDate,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Ngày kết thúc'),
                      subtitle: Text('${_endDate.day}/${_endDate.month}/${_endDate.year}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: _selectEndDate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedVoucherType,
                decoration: const InputDecoration(
                  labelText: 'Loại Voucher',
                  border: OutlineInputBorder(),
                ),
                items: _voucherTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getVoucherTypeDisplayName(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedVoucherType = value!;
                    if (value != 'category_based') {
                      _selectedCategory = null;
                    }
                    if (value != 'specific_products') {
                      _selectedProductIds.clear();
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              if (_selectedVoucherType == 'category_based') ...[
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Danh mục sản phẩm',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],
              if (_selectedVoucherType == 'specific_products') ...[
                const Text(
                  'Chọn sản phẩm áp dụng:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (_isLoadingProducts)
                  const Center(child: CircularProgressIndicator())
                else
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ListView.builder(
                      itemCount: _allProducts.length,
                      itemBuilder: (context, index) {
                        final product = _allProducts[index];
                        final isSelected = _selectedProductIds.contains(product.id);
                        return CheckboxListTile(
                          title: Text(product.name),
                          subtitle: Text(product.category),
                          value: isSelected,
                          onChanged: (value) {
                            _toggleProductSelection(product.id);
                          },
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
          ),
          child: Text(widget.voucher == null ? 'Thêm' : 'Cập nhật'),
        ),
      ],
    );
  }
} 