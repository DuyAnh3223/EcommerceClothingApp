import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/product_combination_model.dart';
import '../../services/product_combination_service.dart';
import '../../services/auth_service.dart'; // Giả định có AuthService để lấy user info
import '../../services/product_service.dart'; // Giả định có ProductService để lấy sản phẩm
import 'package:http/http.dart' as http;
import '../../models/product_model.dart';

class CreateEditCombinationScreen extends StatefulWidget {
  final ProductCombination? combination;
  const CreateEditCombinationScreen({Key? key, this.combination}) : super(key: key);

  @override
  State<CreateEditCombinationScreen> createState() => _CreateEditCombinationScreenState();
}

class _CreateEditCombinationScreenState extends State<CreateEditCombinationScreen> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String description = '';
  String? imageUrl;
  double? discountPrice;
  String status = 'active';
  bool isFeatured = false;
  List<Product> allProducts = [];
  List<Product> selectedProducts = [];
  Set<String> selectedCategories = {};
  bool isLoading = false;
  File? pickedImageFile;

  // Thêm biến tìm kiếm và filter
  final TextEditingController searchController = TextEditingController();
  String searchCategory = '';
  String searchGender = '';
  String searchColor = '';
  String searchSize = '';
  String searchBrand = '';
  List<Product> filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    if (widget.combination != null) {
      name = widget.combination!.name;
      description = widget.combination!.description ?? '';
      imageUrl = widget.combination!.imageUrl;
      discountPrice = widget.combination!.discountPrice;
      status = widget.combination!.status;
      isFeatured = false;
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    setState(() { isLoading = true; });
    final user = await AuthService.getCurrentUser();
    final userId = user.id;
    final result = await ProductService.getProductsByUser(userId);
    if (result['success']) {
      setState(() {
        allProducts = (result['products'] as List)
          .map((e) => Product.fromJson(e))
          .where((p) => p.id != null)
          .toList();
        if (widget.combination != null) {
          selectedProducts = allProducts
            .where((p) => widget.combination!.items.any((item) => item.productId == p.id))
            .toList();
          selectedCategories = selectedProducts.map((e) => e.category).toSet();
        }
        _filterProducts();
        isLoading = false;
      });
    } else {
      setState(() { isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Lỗi tải sản phẩm')),
      );
    }
  }

  void _filterProducts() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredProducts = allProducts.where((p) {
        // Nếu query có nhiều cặp 'attribute:value', tách và lọc tất cả
        final attrFilters = <String, String>{};
        final regex = RegExp(r'(\w+):([^\s]+)');
        for (final match in regex.allMatches(query)) {
          final attr = match.group(1)?.trim();
          final value = match.group(2)?.trim();
          if (attr != null && value != null) {
            attrFilters[attr] = value;
          }
        }
        if (attrFilters.isNotEmpty) {
          // Sản phẩm chỉ hiển thị nếu có ít nhất 1 variant thỏa mãn tất cả điều kiện
          return p.variants.any((variant) {
            // Mỗi điều kiện đều phải đúng với variant này
            return attrFilters.entries.every((entry) =>
              variant.attributeValues.any((attr) =>
                attr.attributeName.toLowerCase() == entry.key &&
                attr.value.toLowerCase().contains(entry.value)
              )
            );
          });
        }
        // Nếu không có dạng attribute:value, tách query thành nhiều từ khóa (bằng dấu phẩy hoặc dấu cách)
        final keywords = query.split(RegExp(r'[\s,]+')).where((k) => k.isNotEmpty).toList();
        if (keywords.isNotEmpty) {
          // Sản phẩm hiển thị nếu có ít nhất 1 từ khóa khớp với tên, category, genderTarget hoặc bất kỳ thuộc tính động nào
          return keywords.any((kw) {
            if (p.name.toLowerCase().contains(kw) ||
                p.category.toLowerCase().contains(kw) ||
                p.genderTarget.toLowerCase().contains(kw)) {
              return true;
            }
            for (final variant in p.variants) {
              for (final attr in variant.attributeValues) {
                if (attr.value.toLowerCase().contains(kw) ||
                    attr.attributeName.toLowerCase().contains(kw)) {
                  return true;
                }
              }
            }
            return false;
          });
        }
        // Nếu query rỗng, trả về tất cả
        return query.isEmpty;
      }).toList();
    });
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() { pickedImageFile = File(picked.path); });
      // Upload lên server
      final uri = Uri.parse('http://127.0.0.1/EcommerceClothingApp/API/uploads/upload_image.php');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('image', picked.path));
      final response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final data = json.decode(respStr);
        if (data['success'] == true) {
          setState(() { imageUrl = data['filename']; });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Lỗi upload ảnh')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi upload ảnh')),
        );
      }
    }
  }

  void _onProductTap(Product product) {
    setState(() {
      final isSelected = selectedProducts.any((p) => p.id == product.id);
      final isCategoryDuplicate = !isSelected && selectedCategories.contains(product.category);
      if (isSelected) {
        selectedProducts.removeWhere((p) => p.id == product.id);
        selectedCategories.remove(product.category);
      } else if (!isCategoryDuplicate) {
        selectedProducts.add(product);
        selectedCategories.add(product.category);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không được chọn 2 sản phẩm cùng danh mục!')),
        );
      }
    });
  }

  void _onEditSelectedProduct(Product product) async {
    final idx = selectedProducts.indexWhere((p) => p.id == product.id);
    // Gọi API lấy variants và thuộc tính động
    final response = await http.get(Uri.parse('http://127.0.0.1/EcommerceClothingApp/API/variants_attributes/get_variants.php?product_id=${product.id}'));
    if (response.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không lấy được thuộc tính sản phẩm!')));
      return;
    }
    final data = json.decode(response.body);
    if (data['success'] != true || data['variants'] == null || data['variants'].isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sản phẩm chưa có thuộc tính!')));
      return;
    }
    // Lấy tất cả thuộc tính và giá trị có thể có từ các variant
    final Map<String, Set<String>> attributeValues = {};
    for (final variant in data['variants']) {
      for (final attr in variant['attribute_values']) {
        final attrName = attr['attribute_name'];
        final value = attr['value'];
        attributeValues.putIfAbsent(attrName, () => <String>{});
        attributeValues[attrName]!.add(value);
      }
    }
    // Lấy giá trị hiện tại
    Map<String, String?> selectedValues = {
      'genderTarget': product.genderTarget,
    };
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chỉnh sửa thuộc tính sản phẩm'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: attributeValues.entries.map((entry) {
              final attr = entry.key;
              final values = entry.value.toList();
              return DropdownButtonFormField<String>(
                value: selectedValues[attr],
                items: values.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                onChanged: (v) => selectedValues[attr] = v,
                decoration: InputDecoration(labelText: attr),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                selectedProducts[idx] = Product(
                  id: product.id,
                  name: product.name,
                  description: product.description ?? '',
                  category: product.category,
                  genderTarget: selectedValues['genderTarget'] ?? product.genderTarget,
                  mainImage: product.mainImage,
                  createdAt: product.createdAt,
                  updatedAt: product.updatedAt,
                  variants: product.variants,
                );
              });
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _onSubmit() async {
    if (!_formKey.currentState!.validate() || selectedProducts.length < 2) {
      if (selectedProducts.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn ít nhất 2 sản phẩm!')),
        );
      }
      return;
    }
    _formKey.currentState!.save();
    setState(() { isLoading = true; });
    final user = await AuthService.getCurrentUser();
    final userId = user.id;
    final creatorType = user.role;
    final categories = selectedProducts.map((p) => p.category).toList();
    final items = selectedProducts.map((p) {
      final variant = p.variants.isNotEmpty ? p.variants.first : null;
      return {
        'product_id': p.id,
        if (variant != null) 'variant_id': variant.id,
        if (variant != null && variant.attributeValues.isNotEmpty)
          'attributes': {
            for (var attr in variant.attributeValues) attr.attributeName: attr.value
          },
      };
    }).toList();
    final result = await ProductCombinationService.createCombination(
      name: name,
      description: description,
      imageUrl: imageUrl,
      discountPrice: discountPrice,
      status: status,
      createdBy: userId,
      creatorType: creatorType,
      categories: categories,
      items: items,
    );
    setState(() { isLoading = false; });
    if (result['success']) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tạo tổ hợp thành công!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Lỗi tạo tổ hợp')),
      );
    }
  }

  // Hàm tiện ích để lấy URL ảnh đúng
  String getProductImageUrl(String? mainImage) {
    if (mainImage == null || mainImage.isEmpty) return '';
    return mainImage.startsWith('http')
        ? mainImage
        : 'http://127.0.0.1/EcommerceClothingApp/API/uploads/serve_image.php?file=$mainImage';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.combination == null ? 'Tạo tổ hợp sản phẩm' : 'Sửa tổ hợp sản phẩm')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cột 1: Tìm kiếm, chọn sản phẩm, sản phẩm đã chọn
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ô tìm kiếm
                        TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            labelText: 'Tìm kiếm sản phẩm',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      searchController.clear();
                                      _filterProducts();
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (v) => _filterProducts(),
                        ),
                        const SizedBox(height: 8),
                        // TODO: Thêm filter nâng cao (category, gender, color, size, brand...)
                        // Danh sách sản phẩm
                        Expanded(
                          child: filteredProducts.isEmpty
                              ? const Center(child: Text('Không có sản phẩm phù hợp'))
                              : GridView.builder(
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 2.8,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                                  itemCount: filteredProducts.length,
                                  itemBuilder: (context, idx) {
                                    final product = filteredProducts[idx];
                                    final isSelected = selectedProducts.any((p) => p.id == product.id);
                                    final isCategoryDuplicate = !isSelected && selectedCategories.contains(product.category);
                                    return GestureDetector(
                                      onTap: () => _onProductTap(product),
                                      child: Card(
                                        color: isSelected
                                            ? Colors.blue.shade100
                                            : isCategoryDuplicate
                                                ? Colors.grey.shade200
                                                : null,
                                        child: Row(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Image.network(
                                                getProductImageUrl(product.mainImage),
                                                width: 40,
                                                height: 40,
                                                errorBuilder: (c, e, s) => const Icon(Icons.image),
                                              ),
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                                                  Text(product.category, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                                ],
                                              ),
                                            ),
                                            if (isSelected)
                                              const Icon(Icons.check_circle, color: Colors.blue),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 8),
                        // Khung sản phẩm đã chọn
                        Text('Sản phẩm đã chọn:', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 70,
                          child: selectedProducts.isEmpty
                              ? const Center(child: Text('Chưa chọn sản phẩm nào'))
                              : ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: selectedProducts.length,
                                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                                  itemBuilder: (context, idx) {
                                    final p = selectedProducts[idx];
                                    return GestureDetector(
                                      onTap: () => _onEditSelectedProduct(p),
                                      child: Column(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              getProductImageUrl(p.mainImage),
                                              width: 48,
                                              height: 48,
                                              fit: BoxFit.cover,
                                              errorBuilder: (c, e, s) => const Icon(Icons.image),
                                            ),
                                          ),
                                          Text(p.name, style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Cột 2: Form thông tin tổ hợp
                  Expanded(
                    flex: 3,
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          TextFormField(
                            initialValue: name,
                            decoration: const InputDecoration(labelText: 'Tên tổ hợp'),
                            validator: (v) => v == null || v.isEmpty ? 'Bắt buộc' : null,
                            onSaved: (v) => name = v!,
                          ),
                          TextFormField(
                            initialValue: description,
                            decoration: const InputDecoration(labelText: 'Mô tả'),
                            onSaved: (v) => description = v ?? '',
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.image),
                                label: const Text('Chọn ảnh đại diện'),
                                onPressed: _pickAndUploadImage,
                              ),
                              if (imageUrl != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 16),
                                  child: Image.network(
                                    getProductImageUrl(imageUrl),
                                    height: 60,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            initialValue: discountPrice?.toString(),
                            decoration: const InputDecoration(labelText: 'Giá ưu đãi'),
                            keyboardType: TextInputType.number,
                            onSaved: (v) => discountPrice = double.tryParse(v ?? ''),
                          ),
                          DropdownButtonFormField<String>(
                            value: status,
                            items: const [
                              DropdownMenuItem(value: 'active', child: Text('Hoạt động')),
                              DropdownMenuItem(value: 'inactive', child: Text('Không hoạt động')),
                            ],
                            onChanged: (v) => setState(() => status = v!),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _onSubmit,
                            child: Text(widget.combination == null ? 'Tạo tổ hợp' : 'Cập nhật tổ hợp'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
} 