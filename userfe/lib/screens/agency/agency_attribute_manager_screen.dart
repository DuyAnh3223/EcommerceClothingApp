import 'package:flutter/material.dart';
import '../../services/agency_service.dart';

class AgencyAttributeManagerScreen extends StatefulWidget {
  const AgencyAttributeManagerScreen({Key? key}) : super(key: key);

  @override
  State<AgencyAttributeManagerScreen> createState() => _AgencyAttributeManagerScreenState();
}

class _AgencyAttributeManagerScreenState extends State<AgencyAttributeManagerScreen> {
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
    try {
      final result = await AgencyService.getAttributes();
      if (result['success']) {
        setState(() {
          attributes = result['attributes'];
          isLoading = false;
        });
      } else {
        setState(() { isLoading = false; });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Lỗi tải thuộc tính'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() { isLoading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadAttributeValues(int attributeId) async {
    setState(() { isLoading = true; });
    try {
      final result = await AgencyService.getAttributeValues(attributeId: attributeId);
      if (result['success']) {
        setState(() {
          attributeValues = result['values'];
          isLoading = false;
        });
      } else {
        setState(() { isLoading = false; });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Lỗi tải giá trị thuộc tính'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() { isLoading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addAttribute() async {
    final name = attrController.text.trim();
    if (name.isEmpty) return;
    
    try {
      final result = await AgencyService.addAttribute(name: name);
      if (result['success']) {
        attrController.clear();
        _loadAttributes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Lỗi thêm thuộc tính'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAttribute(int attributeId) async {
    try {
      final result = await AgencyService.deleteAttribute(attributeId: attributeId);
      if (result['success']) {
        if (selectedAttributeId == attributeId) {
          selectedAttributeId = null;
          attributeValues = [];
        }
        _loadAttributes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Lỗi xóa thuộc tính'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addAttributeValue() async {
    final value = valueController.text.trim();
    if (value.isEmpty || selectedAttributeId == null) return;
    
    try {
      final result = await AgencyService.addAttributeValue(
        attributeId: selectedAttributeId!,
        value: value,
      );
      if (result['success']) {
        valueController.clear();
        _loadAttributeValues(selectedAttributeId!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Lỗi thêm giá trị'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAttributeValue(int valueId) async {
    try {
      final result = await AgencyService.deleteAttributeValue(valueId: valueId);
      if (result['success']) {
        _loadAttributeValues(selectedAttributeId!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Lỗi xóa giá trị'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý thuộc tính & giá trị Agency'),
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
                        const Text(
                          'Danh sách thuộc tính',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: attrController,
                                decoration: const InputDecoration(
                                  labelText: 'Tên thuộc tính',
                                  border: OutlineInputBorder(),
                                ),
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
                              const Text(
                                'Giá trị thuộc tính',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: valueController,
                                      decoration: const InputDecoration(
                                        labelText: 'Giá trị',
                                        border: OutlineInputBorder(),
                                      ),
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