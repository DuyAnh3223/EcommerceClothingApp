import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AttributeManagerScreen extends StatefulWidget {
  const AttributeManagerScreen({Key? key}) : super(key: key);

  @override
  State<AttributeManagerScreen> createState() => _AttributeManagerScreenState();
}

class _AttributeManagerScreenState extends State<AttributeManagerScreen> {
  List<Map<String, dynamic>> attributes = [];
  int? selectedAttributeId;
  List<Map<String, dynamic>> attributeValues = [];
  bool isLoading = false;
  final TextEditingController attrController = TextEditingController();
  final TextEditingController valueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAttributes();
  }

  Future<void> _loadAttributes() async {
    setState(() { isLoading = true; });
    final res = await http.get(Uri.parse('http://localhost/EcommerceClothingApp/API/variants_attributes/get_attributes.php'));
    final data = json.decode(res.body);
    if (data['success'] == true) {
      setState(() {
        attributes = List<Map<String, dynamic>>.from(data['attributes']);
        isLoading = false;
      });
    } else {
      setState(() { isLoading = false; });
    }
  }

  Future<void> _loadAttributeValues(int attributeId) async {
    setState(() { isLoading = true; });
    final res = await http.get(Uri.parse('http://localhost/EcommerceClothingApp/API/variants_attributes/get_attribute_values.php?attribute_id=$attributeId'));
    final data = json.decode(res.body);
    if (data['success'] == true) {
      setState(() {
        attributeValues = List<Map<String, dynamic>>.from(data['values']);
        isLoading = false;
      });
    } else {
      setState(() { isLoading = false; });
    }
  }

  Future<void> _addAttribute() async {
    final name = attrController.text.trim();
    if (name.isEmpty) return;
    final res = await http.post(
      Uri.parse('http://localhost/EcommerceClothingApp/API/variants_attributes/add_attribute.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'name': name}),
    );
    final data = json.decode(res.body);
    if (data['success'] == true) {
      attrController.clear();
      _loadAttributes();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thêm thuộc tính thành công'), backgroundColor: Colors.green));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Lỗi'), backgroundColor: Colors.red));
    }
  }

  Future<void> _deleteAttribute(int attributeId) async {
    final res = await http.delete(
      Uri.parse('http://localhost/EcommerceClothingApp/API/variants_attributes/delete_attribute.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'attribute_id': attributeId}),
    );
    final data = json.decode(res.body);
    if (data['success'] == true) {
      if (selectedAttributeId == attributeId) {
        selectedAttributeId = null;
        attributeValues = [];
      }
      _loadAttributes();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa thuộc tính thành công'), backgroundColor: Colors.green));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Lỗi'), backgroundColor: Colors.red));
    }
  }

  Future<void> _addAttributeValue() async {
    final value = valueController.text.trim();
    if (value.isEmpty || selectedAttributeId == null) return;
    final res = await http.post(
      Uri.parse('http://localhost/EcommerceClothingApp/API/variants_attributes/add_attribute_value.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'attribute_id': selectedAttributeId, 'value': value}),
    );
    final data = json.decode(res.body);
    if (data['success'] == true) {
      valueController.clear();
      _loadAttributeValues(selectedAttributeId!);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thêm giá trị thành công'), backgroundColor: Colors.green));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Lỗi'), backgroundColor: Colors.red));
    }
  }

  Future<void> _deleteAttributeValue(int valueId) async {
    final res = await http.delete(
      Uri.parse('http://localhost/EcommerceClothingApp/API/variants_attributes/delete_attribute_value.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'value_id': valueId}),
    );
    final data = json.decode(res.body);
    if (data['success'] == true) {
      _loadAttributeValues(selectedAttributeId!);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa giá trị thành công'), backgroundColor: Colors.green));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Lỗi'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý thuộc tính & giá trị'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Danh sách thuộc tính
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Danh sách thuộc tính', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: attrController,
                                decoration: const InputDecoration(labelText: 'Tên thuộc tính', border: OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _addAttribute,
                              child: const Text('Thêm'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: ListView.builder(
                            itemCount: attributes.length,
                            itemBuilder: (context, index) {
                              final attr = attributes[index];
                              return ListTile(
                                title: Text(attr['name']),
                                selected: selectedAttributeId == attr['id'],
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteAttribute(attr['id']),
                                ),
                                onTap: () {
                                  setState(() {
                                    selectedAttributeId = attr['id'];
                                  });
                                  _loadAttributeValues(attr['id']);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Danh sách giá trị thuộc tính
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: selectedAttributeId == null
                        ? const Center(child: Text('Chọn một thuộc tính để xem/điều chỉnh giá trị'))
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Giá trị thuộc tính', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: valueController,
                                      decoration: const InputDecoration(labelText: 'Giá trị', border: OutlineInputBorder()),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: _addAttributeValue,
                                    child: const Text('Thêm'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: attributeValues.length,
                                  itemBuilder: (context, index) {
                                    final val = attributeValues[index];
                                    return ListTile(
                                      title: Text(val['value']),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deleteAttributeValue(val['value_id']),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
    );
  }
} 