import 'package:flutter/material.dart';

class MaterialManagerScreen extends StatefulWidget {
  const MaterialManagerScreen({Key? key}) : super(key: key);

  @override
  State<MaterialManagerScreen> createState() => _MaterialManagerScreenState();
}

class _MaterialManagerScreenState extends State<MaterialManagerScreen> {
  List<String> materials = ['Cotton', 'Linen', 'Wool', 'Polyester', 'Denim', 'Leather', 'Silk', 'Nylon'];
  final TextEditingController _controller = TextEditingController();
  int? editingIndex;

  void _addMaterial() {
    final material = _controller.text.trim();
    if (material.isNotEmpty && !materials.contains(material)) {
      setState(() {
        materials.add(material);
        _controller.clear();
      });
    }
  }

  void _editMaterial(int index) {
    setState(() {
      editingIndex = index;
      _controller.text = materials[index];
    });
  }

  void _saveEdit() {
    final material = _controller.text.trim();
    if (material.isNotEmpty && editingIndex != null) {
      setState(() {
        materials[editingIndex!] = material;
        editingIndex = null;
        _controller.clear();
      });
    }
  }

  void _deleteMaterial(int index) {
    setState(() {
      materials.removeAt(index);
      if (editingIndex == index) {
        editingIndex = null;
        _controller.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý chất liệu'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Tên chất liệu',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                editingIndex == null
                    ? ElevatedButton(
                        onPressed: _addMaterial,
                        child: const Text('Thêm'),
                      )
                    : ElevatedButton(
                        onPressed: _saveEdit,
                        child: const Text('Lưu'),
                      ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: materials.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(materials[index]),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editMaterial(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteMaterial(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 