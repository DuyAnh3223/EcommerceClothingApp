import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../services/image_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class AddEditVariantScreen extends StatefulWidget {
  final ProductVariant? variant;
  final int productId;

  const AddEditVariantScreen({
    Key? key,
    this.variant,
    required this.productId,
  }) : super(key: key);

  @override
  State<AddEditVariantScreen> createState() => _AddEditVariantScreenState();
}

class _AddEditVariantScreenState extends State<AddEditVariantScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController skuController;
  late TextEditingController priceController;
  late TextEditingController stockController;
  late TextEditingController imageUrlController;
  late TextEditingController priceBacoinController;
  String? selectedStatus;
  bool isLoading = false;
  bool isDropdownLoading = true;
  List<String> statuses = ['active', 'inactive', 'out_of_stock'];

  // Image upload variables
  XFile? _selectedImage;
  Uint8List? _imageBytes;
  bool _shouldRemoveImage = false;

  // Thuộc tính động
  List<Map<String, dynamic>> attributes = [];
  Map<int, List<Map<String, dynamic>>> attributeValues = {}; // attribute_id -> List<value>
  Map<int, int?> selectedValueIds = {}; // attribute_id -> value_id

  @override
  void initState() {
    super.initState();
    skuController = TextEditingController(text: widget.variant?.sku ?? '');
    priceController = TextEditingController(text: widget.variant?.price.toString() ?? '');
    stockController = TextEditingController(text: widget.variant?.stock.toString() ?? '');
    imageUrlController = TextEditingController(text: widget.variant?.imageUrl ?? '');
    selectedStatus = widget.variant?.status ?? statuses.first;
    priceBacoinController = TextEditingController(text: widget.variant?.priceBacoin?.toString() ?? '');
    _loadAttributesAndValues();
  }

  Future<void> _loadAttributesAndValues() async {
    setState(() { isDropdownLoading = true; });
    try {
      // Lấy danh sách thuộc tính
      final attrRes = await http.get(Uri.parse('http://127.0.0.1/EcommerceClothingApp/API/admin/variants_attributes/get_attributes.php?created_by=6'));
      final attrData = json.decode(attrRes.body);
      if (attrData['success'] == true) {
        attributes = List<Map<String, dynamic>>.from(attrData['attributes']);
        // Lấy giá trị cho từng thuộc tính
        for (var attr in attributes) {
          final attrId = attr['id'];
          final valRes = await http.get(Uri.parse('http://127.0.0.1/EcommerceClothingApp/API/admin/variants_attributes/get_attribute_values.php?attribute_id=$attrId'));
          final valData = json.decode(valRes.body);
          if (valData['success'] == true) {
            attributeValues[attrId] = List<Map<String, dynamic>>.from(valData['values']);
          } else {
            attributeValues[attrId] = [];
          }
        }
        // Nếu là sửa, map giá trị đã chọn
        if (widget.variant != null) {
          for (var av in widget.variant!.attributeValues) {
            selectedValueIds[av.attributeId] = av.valueId;
          }
        } else {
          for (var attr in attributes) {
            selectedValueIds[attr['id']] = null;
          }
        }
      }
      setState(() { isDropdownLoading = false; });
    } catch (e) {
      setState(() { isDropdownLoading = false; });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        if (mounted) {
          setState(() {
            _selectedImage = image;
            _imageBytes = bytes;
            _shouldRemoveImage = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi chọn hình ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageBytes == null) return null;

    try {
      final result = await ImageService.uploadImageFromBytes(_imageBytes!);
      if (result['success'] == true) {
        return result['filename'];
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi upload hình ảnh: ${result['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi upload hình ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _saveVariant() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedValueIds.values.any((v) => v == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn đầy đủ giá trị cho tất cả thuộc tính!'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() { isLoading = true; });
    try {
      // Upload hình ảnh nếu có
      String? imageUrl;
      if (_imageBytes != null) {
        imageUrl = await _uploadImage();
        if (imageUrl == null) {
          setState(() { isLoading = false; });
          return;
        }
      } else if (_shouldRemoveImage) {
        imageUrl = null;
      } else {
        // Giữ nguyên hình ảnh cũ nếu có
        imageUrl = widget.variant?.imageUrl;
      }

      final priceBacoin = double.tryParse(priceBacoinController.text);

      final url = widget.variant == null
          ? 'http://127.0.0.1/EcommerceClothingApp/API/admin/variants_attributes/add_variant.php'
          : 'http://127.0.0.1/EcommerceClothingApp/API/admin/variants_attributes/update_variant.php';
      final data = {
        if (widget.variant != null) 'variant_id': widget.variant!.id,
        'product_id': widget.productId,
        'sku': skuController.text.trim(),
        'attribute_value_ids': selectedValueIds.values.toList(),
        'price': double.parse(priceController.text),
        'stock': int.parse(stockController.text),
        'image_url': imageUrl,
        'status': selectedStatus,
        'price_bacoin': priceBacoin,
      };
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      final responseData = json.decode(response.body);
      if (response.statusCode == 200 && responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message']), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Lỗi không xác định'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() { isLoading = false; });
    }
  }

  Widget _buildAttributeDropdown(Map<String, dynamic> attr) {
    final attrId = attr['id'];
    final attrName = attr['name'];
    final values = attributeValues[attrId] ?? [];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<int>(
        value: selectedValueIds[attrId],
        decoration: InputDecoration(labelText: attrName, border: OutlineInputBorder()),
        items: values.map<DropdownMenuItem<int>>((item) => DropdownMenuItem(
          value: item['value_id'],
          child: Text(item['value']),
        )).toList(),
        onChanged: (val) => setState(() => selectedValueIds[attrId] = val),
        validator: (val) => val == null ? 'Vui lòng chọn $attrName' : null,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {TextInputType? keyboardType, int maxLines = 1, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, border: OutlineInputBorder()),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.variant == null ? "Thêm biến thể" : "Sửa biến thể"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: isDropdownLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Thông tin biến thể', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo[800])),
                    const SizedBox(height: 20),
                    _buildTextField(skuController, "SKU *", validator: (v) => v!.isEmpty ? "SKU không được để trống" : null),
                    ...attributes.map(_buildAttributeDropdown).toList(),
                    _buildTextField(priceController, "Giá *", keyboardType: TextInputType.number, validator: (value) {
                      if (value!.isEmpty) return "Giá không được để trống";
                      if (double.tryParse(value) == null) return "Giá phải là số";
                      if (double.parse(value) <= 0) return "Giá phải lớn hơn 0";
                      return null;
                    }),
                    _buildTextField(stockController, "Tồn kho *", keyboardType: TextInputType.number, validator: (value) {
                      if (value!.isEmpty) return "Tồn kho không được để trống";
                      if (int.tryParse(value) == null) return "Tồn kho phải là số";
                      if (int.parse(value) < 0) return "Tồn kho không được âm";
                      return null;
                    }),
                    _buildTextField(priceBacoinController, "Giá coin (BACoin)"),
                    
                    // Image Upload Section
                    const SizedBox(height: 20),
                    Text(
                      'Hình ảnh biến thể',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Image Preview
                    Container(
                      constraints: const BoxConstraints(
                        minHeight: 200,
                        maxHeight: 400,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade50,
                      ),
                      child: _imageBytes != null
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
                                  height: 200,
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
                              // Nếu đang sửa biến thể, đánh dấu để xóa hình ảnh
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
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: DropdownButtonFormField<String>(
                        value: selectedStatus,
                        decoration: const InputDecoration(labelText: 'Trạng thái', border: OutlineInputBorder()),
                        items: statuses.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
                        onChanged: (val) => setState(() => selectedStatus = val),
                        validator: (val) => val == null || val.isEmpty ? 'Vui lòng chọn trạng thái' : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _saveVariant,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(widget.variant == null ? "Thêm biến thể" : "Lưu thay đổi"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 