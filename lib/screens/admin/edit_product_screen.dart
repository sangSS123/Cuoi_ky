import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProductScreen extends StatefulWidget {
  final String? productId;
  final Map<String, dynamic>? productData;

  const EditProductScreen({super.key, this.productId, this.productData});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _imageController;
  late TextEditingController _categoryController;
  late TextEditingController _quantityController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.productData?['name'] ?? '',
    );
    _priceController = TextEditingController(
      text: widget.productData?['price']?.toString() ?? '',
    );
    _imageController = TextEditingController(
      text: widget.productData?['image'] ?? '',
    );
    _categoryController = TextEditingController(
      text: widget.productData?['id_category'] ?? '',
    );
    _quantityController = TextEditingController(
      text: widget.productData?['quantity']?.toString() ?? '10',
    );
    _descriptionController = TextEditingController(
      text: widget.productData?['description'] ?? '',
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'name': _nameController.text,
      'price': double.parse(_priceController.text),
      'image': _imageController.text,
      'id_category': _categoryController.text,
      'quantity': int.parse(_quantityController.text),
      'description': _descriptionController.text, // Lưu mô tả vào CSDL
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      if (widget.productId == null) {
        await FirebaseFirestore.instance.collection('products').add(data);
      } else {
        await FirebaseFirestore.instance
            .collection('products')
            .doc(widget.productId)
            .update(data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thông tin sản phẩm"),
        backgroundColor: Colors.green,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildInput(_nameController, "Tên hạt giống"),
            _buildInput(_priceController, "Giá tiền", isNumber: true),
            _buildInput(_imageController, "Link ảnh (image)"),
            _buildInput(_categoryController, "Mã danh mục"),
            _buildInput(_quantityController, "Số lượng kho", isNumber: true),
            const SizedBox(height: 10),
            // Ô NHẬP MÔ TẢ CHI TIẾT DÀNH CHO SHOP
            TextFormField(
              controller: _descriptionController,
              maxLines: 8, // Cho phép nhập dài để ghi Nguồn gốc, Hạn sử dụng...
              decoration: const InputDecoration(
                labelText: "Mô tả (Nguồn gốc, Trọng lượng, HDSD, Bảo quản...)",
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _saveProduct,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.all(15),
              ),
              child: const Text(
                "LƯU SẢN PHẨM",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(
    TextEditingController controller,
    String label, {
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (v) => v!.isEmpty ? "Không được để trống" : null,
      ),
    );
  }
}
