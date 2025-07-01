import 'package:flutter/material.dart';
import '../../models/agency_product_model.dart';
import '../../services/agency_service.dart';
import '../../services/image_service.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class AddEditAgencyVariantScreen extends StatefulWidget {
  final int productId;
  final ProductVariant? variant;

  const AddEditAgencyVariantScreen({
    Key? key,
    required this.productId,
    this.variant,
  }) : super(key: key);

  @override
  State<AddEditAgencyVariantScreen> createState() => _AddEditAgencyVariantScreenState();
}

class _AddEditAgencyVariantScreenState extends State<AddEditAgencyVariantScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _skuController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _imageController;
  
  List<Map<String, dynamic>> attributes = [];
  List<Map<String, dynamic>> selectedAttributeValues = [];
  bool isLoading = true;
  bool isSaving = false;
  
  File? _selectedImage;
  Uint8List? _imageBytes;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();
  bool _shouldRemoveImage = false;

  @override
  void initState() {
    super.initState();
    _skuController = TextEditingController(text: widget.variant?.sku ?? '');
    _priceController = TextEditingController(text: widget.variant?.price.toString() ?? '');
    _stockController = TextEditingController(text: widget.variant?.stock.toString() ?? '');
    _imageController = TextEditingController(text: widget.variant?.imageUrl ?? '');
    
    _loadAttributes();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        final file = File(image.path);
        final bytes = await image.readAsBytes();
        
        setState(() {
          _selectedImage = file;
          _imageBytes = bytes;
          _shouldRemoveImage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi chọn hình ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null || _imageBytes == null) {
      return null;
    }

    if (mounted) {
      setState(() {
        _isUploading = true;
      });
    }

    try {
      final result = await ImageService.uploadImageFromBytes(_imageBytes!);

      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }

      if (result['success']) {
        return result['image_url'];
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload thất bại: ${result['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  @override
  void dispose() {
    _skuController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _loadAttributes() async {
    setState(() { isLoading = true; });
    try {
      final result = await AgencyService.getAttributes();
      if (result['success']) {
        setState(() {
          attributes = List<Map<String, dynamic>>.from(result['data']?['attributes'] ?? []);
          isLoading = false;
        });
        
        // Nếu đang sửa variant, load các thuộc tính đã chọn
        if (widget.variant != null) {
          _loadSelectedAttributes();
        }
      } else {
        setState(() { isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Lỗi tải thuộc tính'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      setState(() { isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _loadSelectedAttributes() {
    if (widget.variant != null) {
      // Map các thuộc tính đã chọn từ variant
      for (final attr in attributes) {
        final attrValues = List<Map<String, dynamic>>.from(attr['values'] ?? []);
        for (final variantAttr in widget.variant!.attributes) {
          if (variantAttr.attributeId == attr['id']) {
            final selectedValue = attrValues.firstWhere(
              (value) => value['id'] == variantAttr.id,
              orElse: () => {},
            );
            if (selectedValue.isNotEmpty) {
              selectedAttributeValues.add({
                'attribute_id': attr['id'],
                'attribute_name': attr['name'],
                'value_id': selectedValue['id'],
                'value': selectedValue['value'],
              });
            }
          }
        }
      }
    }
  }

  void _selectAttributeValue(Map<String, dynamic> attribute, Map<String, dynamic> value) {
    setState(() {
      // Xóa giá trị cũ của thuộc tính này nếu có
      selectedAttributeValues.removeWhere((item) => item['attribute_id'] == attribute['id']);
      
      // Thêm giá trị mới
      selectedAttributeValues.add({
        'attribute_id': attribute['id'],
        'attribute_name': attribute['name'],
        'value_id': value['id'],
        'value': value['value'],
      });
    });
  }

  void _removeAttributeValue(int attributeId) {
    setState(() {
      selectedAttributeValues.removeWhere((item) => item['attribute_id'] == attributeId);
    });
  }

  Future<void> _saveVariant() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedAttributeValues.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất một thuộc tính'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() { isSaving = true; });
    
    try {
      // Upload hình ảnh trước nếu có hình ảnh mới được chọn
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadImage();
        if (imageUrl == null) {
          setState(() { isSaving = false; });
          return; // Dừng nếu upload thất bại
        }
      }

      final attributeValueIds = selectedAttributeValues.map((item) => item['value_id'] as int).toList();
      
      Map<String, dynamic> result;
      if (widget.variant == null) {
        // Thêm mới
        result = await AgencyService.addVariant(
          productId: widget.productId,
          sku: _skuController.text.trim(),
          price: double.parse(_priceController.text),
          stock: int.parse(_stockController.text),
          attributeValueIds: attributeValueIds,
          imageUrl: imageUrl,
        );
      } else {
        // Cập nhật
        result = await AgencyService.updateVariant(
          variantId: widget.variant!.id,
          sku: _skuController.text.trim(),
          price: double.parse(_priceController.text),
          stock: int.parse(_stockController.text),
          attributeValueIds: attributeValueIds,
          imageUrl: imageUrl,
        );
      }

      setState(() { isSaving = false; });
      
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Lưu biến thể thành công'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Lỗi lưu biến thể'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      setState(() { isSaving = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.variant == null ? 'Thêm biến thể' : 'Sửa biến thể'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thông tin cơ bản
                    const Text(
                      'Thông tin cơ bản',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _skuController,
                      decoration: const InputDecoration(
                        labelText: 'SKU *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.isEmpty == true ? 'Vui lòng nhập SKU' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Giá (VNĐ) *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty == true) return 'Vui lòng nhập giá';
                        if (double.tryParse(value!) == null) return 'Giá không hợp lệ';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _stockController,
                      decoration: const InputDecoration(
                        labelText: 'Tồn kho *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty == true) return 'Vui lòng nhập tồn kho';
                        if (int.tryParse(value!) == null) return 'Tồn kho không hợp lệ';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Hình ảnh biến thể
                    const Text(
                      'Hình ảnh biến thể',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    
                    // Image Preview
                    GestureDetector(
                      onTap: () {
                        // Hiển thị hình ảnh full size khi click
                        if (_imageBytes != null || 
                            (widget.variant != null && widget.variant!.imageUrl != null && widget.variant!.imageUrl!.isNotEmpty)) {
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
                                      title: const Text('Xem hình ảnh'),
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
                                      child: _imageBytes != null
                                          ? Image.memory(
                                              _imageBytes!,
                                              fit: BoxFit.contain,
                                            )
                                          : Image.network(
                                              'http://127.0.0.1/EcommerceClothingApp/API/uploads/serve_image.php?file=${widget.variant!.imageUrl!}',
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
                        constraints: const BoxConstraints(
                          minHeight: 150,
                          maxHeight: 300,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade50,
                        ),
                        child: Stack(
                          children: [
                            _imageBytes != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.memory(
                                      _imageBytes!,
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                      height: double.infinity,
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
                                  )
                                : (widget.variant != null && widget.variant!.imageUrl != null && widget.variant!.imageUrl!.isNotEmpty)
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          'http://127.0.0.1/EcommerceClothingApp/API/uploads/serve_image.php?file=${widget.variant!.imageUrl!}',
                                          fit: BoxFit.contain,
                                          width: double.infinity,
                                          height: double.infinity,
                                          errorBuilder: (context, error, stackTrace) => const Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.image, size: 64, color: Colors.grey),
                                                SizedBox(height: 8),
                                                Text('Lỗi tải hình ảnh', style: TextStyle(color: Colors.grey)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      )
                                    : Container(
                                        height: 150,
                                        child: const Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.image, size: 64, color: Colors.grey),
                                              SizedBox(height: 8),
                                              Text('Chưa có hình ảnh', style: TextStyle(color: Colors.grey)),
                                            ],
                                          ),
                                        ),
                                      ),
                            // Overlay để hiển thị icon zoom khi có hình ảnh
                            if (_imageBytes != null || 
                                (widget.variant != null && widget.variant!.imageUrl != null && widget.variant!.imageUrl!.isNotEmpty))
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(
                                    Icons.zoom_in,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Image Selection Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Chọn từ thư viện'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Chụp ảnh'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Nút xóa hình ảnh (chỉ hiển thị khi có hình ảnh)
                    if ((_imageBytes != null) || 
                        (widget.variant != null && widget.variant!.imageUrl != null && widget.variant!.imageUrl!.isNotEmpty))
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedImage = null;
                                _imageBytes = null;
                              });
                              // Nếu đang sửa variant, đánh dấu để xóa hình ảnh
                              if (widget.variant != null) {
                                _shouldRemoveImage = true;
                              }
                            },
                            icon: const Icon(Icons.delete, color: Colors.red),
                            label: const Text('Xóa hình ảnh', style: TextStyle(color: Colors.red)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Thuộc tính đã chọn
                    if (selectedAttributeValues.isNotEmpty) ...[
                      const Text(
                        'Thuộc tính đã chọn',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: selectedAttributeValues.map((item) {
                          return Chip(
                            label: Text('${item['attribute_name']}: ${item['value']}'),
                            onDeleted: () => _removeAttributeValue(item['attribute_id']),
                            deleteIcon: const Icon(Icons.close, size: 18),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    // Chọn thuộc tính
                    const Text(
                      'Chọn thuộc tính',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    
                    ...attributes.map((attribute) {
                      final values = List<Map<String, dynamic>>.from(attribute['values'] ?? []);
                      final isSelected = selectedAttributeValues.any((item) => item['attribute_id'] == attribute['id']);
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          title: Text(
                            attribute['name'],
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.blue : Colors.black,
                            ),
                          ),
                          subtitle: isSelected 
                              ? Text('Đã chọn: ${selectedAttributeValues.firstWhere((item) => item['attribute_id'] == attribute['id'])['value']}')
                              : const Text('Chưa chọn'),
                          children: values.map((value) {
                            final isValueSelected = selectedAttributeValues.any((item) => 
                                item['attribute_id'] == attribute['id'] && item['value_id'] == value['id']);
                            
                            return ListTile(
                              title: Text(value['value']),
                              trailing: isValueSelected ? const Icon(Icons.check, color: Colors.green) : null,
                              onTap: () => _selectAttributeValue(attribute, value),
                            );
                          }).toList(),
                        ),
                      );
                    }).toList(),
                    
                    const SizedBox(height: 24),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : _saveVariant,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                widget.variant == null ? 'Thêm biến thể' : 'Cập nhật biến thể',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 