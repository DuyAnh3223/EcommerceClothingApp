import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/agency_product_combo_model.dart';
import '../../../services/agency_product_combo_service.dart';
import '../../../services/auth_service.dart'; // Giả định có AuthService để lấy user info
import '../../../services/agency_service.dart'; // Sử dụng AgencyService để lấy sản phẩm
import 'package:http/http.dart' as http;
import '../../../models/agency_product_model.dart';

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
  List<AgencyProduct> allProducts = [];
  List<AgencyProduct> selectedProducts = [];
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
  List<AgencyProduct> filteredProducts = [];

  // Thay vì chỉ lưu selectedProducts, ta lưu selectedVariants: Map<productId, variant>
  Map<int, ProductVariant> selectedVariants = {};

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
      // Nếu có items, map selectedVariants
      for (final item in widget.combination!.items) {
        AgencyProduct? product;
        try {
          product = allProducts.firstWhere((p) => p.id == item.productId);
        } catch (e) {
          product = null;
        }
        if (product != null && product.variants.isNotEmpty) {
          final variant = product.variants.firstWhere(
            (v) => v.id == item.variantId,
            orElse: () => product!.variants.first,
          );
          selectedVariants[product.id!] = variant;
        }
      }
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
    final userId = user['id'];
    final result = await AgencyService.getProductsByUser(userId);
    if (result['success']) {
      setState(() {
        allProducts = (result['products'] as List)
          .map((e) => AgencyProduct.fromJson(e))
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
                variant.attributes.any((attr) =>
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
              for (final attr in variant.attributes) {
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

  void _onProductTap(AgencyProduct product) {
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

  void _onEditSelectedProduct(AgencyProduct product) async {
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
                selectedProducts[idx] = AgencyProduct(
                  id: product.id,
                  name: product.name,
                  description: product.description ?? '',
                  category: product.category,
                  genderTarget: selectedValues['genderTarget'] ?? product.genderTarget,
                  mainImage: product.mainImage,
                  isAgencyProduct: product.isAgencyProduct,
                  status: product.status,
                  platformFeeRate: product.platformFeeRate,
                  createdAt: product.createdAt,
                  updatedAt: product.updatedAt,
                  approvalStatus: product.approvalStatus,
                  reviewNotes: product.reviewNotes,
                  reviewedAt: product.reviewedAt,
                  reviewerName: product.reviewerName,
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

  // Sửa lại hàm _onSubmit để đảm bảo form validate và có thông báo khi nhấn nút
  void _onSubmit() async {
    print('Submit pressed');
    // Kiểm tra validate form
    final form = _formKey.currentState;
    if (form == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Có lỗi xảy ra với form!')),
      );
      return;
    }
    if (!form.validate()) {
      // Nếu form không hợp lệ, show thông báo lỗi
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin hợp lệ!')),
      );
      return;
    }
    if (selectedProducts.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất 2 sản phẩm!')),
      );
      return;
    }
    form.save();
    setState(() { isLoading = true; });

    try {
      final user = await AuthService.getCurrentUser();
      final userId = user['id'];
      final creatorType = user['role'];
      final categories = selectedProducts.map((p) => p.category).toList();
      final items = selectedProducts.map((p) {
        // Sử dụng selectedVariants nếu có, nếu không lấy variant đầu tiên
        final variant = selectedVariants[p.id] ?? (p.variants.isNotEmpty ? p.variants.first : null);
        return {
          'product_id': p.id,
          if (variant != null) 'variant_id': variant.id,
          if (variant != null && variant.attributes.isNotEmpty)
            'attributes': {
              for (var attr in variant.attributes) attr.attributeName: attr.value
            },
        };
      }).toList();
      final result = await ProductCombinationService.createCombination(
        name: name,
        description: description,
        imageUrl: imageUrl,
        discountPrice: discountPrice,
        status: status,
        categories: categories,
        items: items,
      );
      setState(() { isLoading = false; });
      if (result['success'] == true) {
        // Đảm bảo show thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tạo tổ hợp thành công!')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Lỗi tạo tổ hợp')),
        );
      }
    } catch (e) {
      setState(() { isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
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

  // Hàm tiện ích để lấy chuỗi thuộc tính của variant, ví dụ: color: white, size: X, brand: Adidas
  String getVariantAttributesString(ProductVariant v) {
    if (v.attributes.isEmpty) return '';
    return v.attributes
        .map((attr) => '${attr.attributeName}: ${attr.value}')
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
        title: Text(
          widget.combination == null ? 'Tạo tổ hợp sản phẩm' : 'Sửa tổ hợp sản phẩm',
          style: const TextStyle(
            color: Colors.cyanAccent,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Cột 1: Tìm kiếm, chọn sản phẩm, sản phẩm đã chọn
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // Ô tìm kiếm
                        TextField(
                          controller: searchController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Tìm kiếm sản phẩm',
                            labelStyle: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                            prefixIcon: const Icon(Icons.search, color: Colors.cyanAccent),
                            filled: true,
                            fillColor: Colors.grey[850],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.cyanAccent, width: 2),
                            ),
                          ),
                          onChanged: (v) => _filterProducts(),
                        ),
                        const SizedBox(height: 16),
                        // Danh sách sản phẩm
                        Expanded(
                          child: filteredProducts.isEmpty
                              ? const Center(child: Text('Không có sản phẩm phù hợp', style: TextStyle(color: Colors.white70)))
                              : GridView.builder(
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 2.8,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                                  itemCount: filteredProducts.length,
                                  itemBuilder: (context, idx) {
                                    final product = filteredProducts[idx];
                                    final isSelected = selectedProducts.any((p) => p.id == product.id);
                                    final isCategoryDuplicate = !isSelected && selectedCategories.contains(product.category);
                                    return GestureDetector(
                                      onTap: () => _onProductTap(product),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 150),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Colors.cyan[900]
                                              : isCategoryDuplicate
                                                  ? Colors.grey[800]
                                                  : Colors.grey[850],
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isSelected ? Colors.cyanAccent : Colors.transparent,
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.12),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: <Widget>[
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: Image.network(
                                                  getProductImageUrl(product.mainImage),
                                                  width: 80,
                                                  height: 80,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (c, e, s) => const Icon(Icons.image, color: Colors.white38, size: 48),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: <Widget>[
                                                  Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                                  Text(product.category, style: TextStyle(fontSize: 12, color: Colors.cyanAccent.withOpacity(0.7))),
                                                ],
                                              ),
                                            ),
                                            if (isSelected)
                                              const Icon(Icons.check_circle, color: Colors.cyanAccent),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),
                  // Cột 2: Form thông tin tổ hợp
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // Sử dụng Expanded + Stack để tổng giá gốc nằm fix ở dưới cùng
                        Expanded(
                          flex: 1,
                          child: Card(
                            color: Colors.grey[850],
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: selectedProducts.isEmpty
                                  ? const Center(child: Text('Chưa chọn sản phẩm nào', style: TextStyle(color: Colors.white70)))
                                  : Stack(
                                      children: [
                                        // List các biến thể và giá tiền (scrollable)
                                        Positioned.fill(
                                          child: Padding(
                                            padding: const EdgeInsets.only(bottom: 60), // chừa chỗ cho tổng giá gốc
                                            child: ListView.separated(
                                              itemCount: selectedProducts.length,
                                              separatorBuilder: (context, idx) => const SizedBox(height: 12),
                                              itemBuilder: (context, idx) {
                                                final p = selectedProducts[idx];
                                                final variant = selectedVariants[p.id] ?? (p.variants.isNotEmpty ? p.variants.first : null);
                                                return GestureDetector(
                                                  onTap: () async {
                                                    if (p.variants.length <= 1) return;
                                                    ProductVariant? newVariant = await showDialog<ProductVariant>(
                                                      context: context,
                                                      builder: (context) => SimpleDialog(
                                                        backgroundColor: Colors.grey[900],
                                                        title: Text('Chọn biến thể cho ${p.name}', style: const TextStyle(color: Colors.cyanAccent)),
                                                        children: p.variants.map((v) {
                                                          final attrString = getVariantAttributesString(v);
                                                          return ListTile(
                                                            leading: v.imageUrl != null && v.imageUrl!.isNotEmpty
                                                                ? Image.network(getProductImageUrl(v.imageUrl), width: 64, height: 64, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.image, color: Colors.white38, size: 48))
                                                                : const Icon(Icons.image, color: Colors.white38, size: 48),
                                                            title: Text(
                                                              attrString.isNotEmpty
                                                                  ? attrString
                                                                  : v.attributes.isNotEmpty
                                                                      ? v.attributes
                                                                          .map((attr) => '${attr.attributeName}: ${attr.value}')
                                                                          .join(', ')
                                                                      : '',
                                                              style: const TextStyle(color: Colors.white),
                                                              maxLines: 2,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                            subtitle: Text('Giá: ${v.price?.toStringAsFixed(0) ?? 'N/A'} đ', style: const TextStyle(color: Colors.cyanAccent)),
                                                            selected: variant?.id == v.id,
                                                            selectedTileColor: Colors.cyan[900],
                                                            onTap: () => Navigator.pop(context, v),
                                                          );
                                                        }).toList(),
                                                      ),
                                                    );
                                                    if (newVariant != null) {
                                                      setState(() {
                                                        selectedVariants[p.id!] = newVariant;
                                                      });
                                                    }
                                                  },
                                                  child: Row(
                                                    crossAxisAlignment: CrossAxisAlignment.center,
                                                    children: <Widget>[
                                                      ClipRRect(
                                                        borderRadius: BorderRadius.circular(12),
                                                        child: variant != null && variant.imageUrl != null && variant.imageUrl!.isNotEmpty
                                                            ? Image.network(getProductImageUrl(variant.imageUrl), width: 64, height: 64, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.image, color: Colors.white38, size: 48))
                                                            : Image.network(getProductImageUrl(p.mainImage), width: 64, height: 64, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.image, color: Colors.white38, size: 48)),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      // Tên sản phẩm và thuộc tính
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            Text(
                                                              p.name,
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                                            ),
                                                            if (variant != null && variant.attributes.isNotEmpty)
                                                              Text(
                                                                getVariantAttributesString(variant),
                                                                style: const TextStyle(fontSize: 12, color: Colors.cyanAccent),
                                                                maxLines: 2,
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                          ],
                                                        ),
                                                      ),
                                                      // Giá tiền căn chỉnh cùng hàng
                                                      Container(
                                                        width: 100,
                                                        alignment: Alignment.centerRight,
                                                        child: Text(
                                                          variant?.price != null ? '${variant!.price!.toStringAsFixed(0)} đ' : 'Chưa có giá',
                                                          style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.cyanAccent, fontSize: 16),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        // Tổng giá gốc fix ở dưới cùng
                                        Positioned(
                                          left: 0,
                                          right: 0,
                                          bottom: 0,
                                          child: Container(
                                            color: Colors.grey[900]?.withOpacity(0.95),
                                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                            child: Align(
                                              alignment: Alignment.centerRight,
                                              child: Builder(
                                                builder: (context) {
                                                  double total = 0;
                                                  for (final p in selectedProducts) {
                                                    final variant = selectedVariants[p.id] ?? (p.variants.isNotEmpty ? p.variants.first : null);
                                                    if (variant?.price != null) total += variant!.price!;
                                                  }
                                                  return Text(
                                                    'Tổng giá gốc: ${total.toStringAsFixed(0)} đ',
                                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent, fontSize: 20),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          flex: 1,
                          child: Card(
                            color: Colors.grey[850],
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: SingleChildScrollView(
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      // Giá ưu đãi
                                      TextFormField(
                                        initialValue: discountPrice?.toString(),
                                        style: const TextStyle(color: Colors.white),
                                        decoration: InputDecoration(
                                          labelText: 'Giá ưu đãi',
                                          labelStyle: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: const BorderSide(color: Colors.cyanAccent, width: 2),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey[900],
                                        ),
                                        keyboardType: TextInputType.number,
                                        onSaved: (v) => discountPrice = double.tryParse(v ?? ''),
                                      ),
                                      const SizedBox(height: 16),
                                      // Form nhập thông tin tổ hợp
                                      TextFormField(
                                        initialValue: name,
                                        style: const TextStyle(color: Colors.white),
                                        decoration: InputDecoration(
                                          labelText: 'Tên tổ hợp',
                                          labelStyle: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: const BorderSide(color: Colors.cyanAccent, width: 2),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey[900],
                                        ),
                                        validator: (v) => v == null || v.isEmpty ? 'Bắt buộc' : null,
                                        onSaved: (v) => name = v!,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        initialValue: description,
                                        style: const TextStyle(color: Colors.white),
                                        decoration: InputDecoration(
                                          labelText: 'Mô tả',
                                          labelStyle: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: const BorderSide(color: Colors.cyanAccent, width: 2),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey[900],
                                        ),
                                        onSaved: (v) => description = v ?? '',
                                      ),
                                      const SizedBox(height: 12),
                                      DropdownButtonFormField<String>(
                                        value: status,
                                        dropdownColor: Colors.grey[900],
                                        style: const TextStyle(color: Colors.white),
                                        decoration: InputDecoration(
                                          labelText: 'Trạng thái',
                                          labelStyle: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                          filled: true,
                                          fillColor: Colors.grey[900],
                                        ),
                                        items: const [
                                          DropdownMenuItem(value: 'active', child: Text('Hoạt động', style: TextStyle(color: Colors.cyanAccent))),
                                          DropdownMenuItem(value: 'inactive', child: Text('Không hoạt động', style: TextStyle(color: Colors.cyanAccent))),
                                        ],
                                        onChanged: (v) => setState(() => status = v!),
                                      ),
                                      const SizedBox(height: 20),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.cyanAccent,
                                            foregroundColor: Colors.black,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(vertical: 18),
                                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                            elevation: 2,
                                          ),
                                          onPressed: _onSubmit,
                                          child: Text(widget.combination == null ? 'Tạo tổ hợp' : 'Cập nhật tổ hợp'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}