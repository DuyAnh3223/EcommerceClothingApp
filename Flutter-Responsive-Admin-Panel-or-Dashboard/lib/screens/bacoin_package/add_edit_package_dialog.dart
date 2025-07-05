import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/bacoin_package_model.dart';
import '../../constants.dart';

class AddEditPackageDialog extends StatefulWidget {
  final BacoinPackage? package;

  const AddEditPackageDialog({Key? key, this.package}) : super(key: key);

  @override
  State<AddEditPackageDialog> createState() => _AddEditPackageDialogState();
}

class _AddEditPackageDialogState extends State<AddEditPackageDialog> {
  final _formKey = GlobalKey<FormState>();
  final _packageNameController = TextEditingController();
  final _priceVndController = TextEditingController();
  final _bacoinAmountController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool get isEditing => widget.package != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _packageNameController.text = widget.package!.packageName;
      _priceVndController.text = widget.package!.priceVnd.toStringAsFixed(0);
      _bacoinAmountController.text = widget.package!.bacoinAmount.toStringAsFixed(0);
      _descriptionController.text = widget.package!.description ?? '';
    }
  }

  @override
  void dispose() {
    _packageNameController.dispose();
    _priceVndController.dispose();
    _bacoinAmountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final package = BacoinPackage(
        id: isEditing ? widget.package!.id : 0,
        packageName: _packageNameController.text.trim(),
        priceVnd: double.parse(_priceVndController.text),
        bacoinAmount: double.parse(_bacoinAmountController.text),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      Navigator.of(context).pop(package);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'Sửa Gói BACoin' : 'Thêm Gói BACoin Mới'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _packageNameController,
                decoration: const InputDecoration(
                  labelText: 'Tên gói *',
                  hintText: 'Ví dụ: Gói 50K',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên gói';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceVndController,
                decoration: const InputDecoration(
                  labelText: 'Giá VNĐ *',
                  hintText: 'Ví dụ: 50000',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập giá';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'Giá phải lớn hơn 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bacoinAmountController,
                decoration: const InputDecoration(
                  labelText: 'Số lượng BACoin *',
                  hintText: 'Ví dụ: 55000',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.monetization_on),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập số lượng BACoin';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Số lượng BACoin phải lớn hơn 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả (tùy chọn)',
                  hintText: 'Mô tả chi tiết về gói',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
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
          child: Text(isEditing ? 'Cập nhật' : 'Thêm'),
        ),
      ],
    );
  }
} 