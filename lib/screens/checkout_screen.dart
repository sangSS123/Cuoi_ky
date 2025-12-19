import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cart_model.dart';
import 'home_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isLoading = false;
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // --- HÀM XỬ LÝ ĐẶT HÀNG & TRỪ KHO ---
  Future<void> _processOrder(CartProvider cart) async {
    final user = FirebaseAuth.instance.currentUser;
    final String address = _addressController.text.trim();
    final String phone = _phoneController.text.trim();

    if (user == null || cart.items.isEmpty) return;

    if (address.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng nhập đầy đủ địa chỉ và số điện thoại!"),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Sử dụng Batch để thực hiện nhiều lệnh cùng lúc (Lưu đơn + Trừ kho)
    final batch = FirebaseFirestore.instance.batch();

    try {
      // 1. Tạo document đơn hàng mới
      final orderRef = FirebaseFirestore.instance
          .collection('order_history')
          .doc();
      batch.set(orderRef, {
        'userId': user.uid,
        'items': cart.items.values
            .map(
              (item) => {
                'id': item.id,
                'name': item.name,
                'quantity': item.quantity,
                'price': item.price,
                'image': item.image,
              },
            )
            .toList(),
        'totalAmount': cart.totalAmount,
        'address': address,
        'phone': phone,
        'status': 'Chờ xác nhận',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. Lệnh trừ số lượng trong kho cho từng sản phẩm
      for (var item in cart.items.values) {
        final productRef = FirebaseFirestore.instance
            .collection('products')
            .doc(item.id);
        batch.update(productRef, {
          'quantity': FieldValue.increment(
            -item.quantity,
          ), // Trừ đi số lượng khách mua
        });
      }

      // 3. Thực thi batch
      await batch.commit();

      // 4. Xóa giỏ hàng
      await cart.clearCart();

      if (!mounted) return;
      setState(() => _isLoading = false);

      // 5. Hiện thông báo thành công
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Lỗi thanh toán: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Thành công!"),
        content: const Text(
          "Đơn hàng đã được ghi nhận và số lượng kho đã cập nhật.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            },
            child: const Text("VỀ TRANG CHỦ"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Thanh toán đơn hàng"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Thông tin giao hàng",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: "Số điện thoại",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: "Địa chỉ nhận hàng",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                  const Divider(height: 40),
                  const Text(
                    "Sản phẩm thanh toán",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ...cart.items.values.map(
                    (item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Image.network(
                        item.image,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                      title: Text(item.name),
                      trailing: Text(
                        "${item.quantity} x ${item.price.toInt()}đ",
                      ),
                    ),
                  ),
                  const Divider(height: 30),

                  // --- PHẦN QR CODE THANH TOÁN ---
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          "Quét QR để chuyển khoản thanh toán",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Image.asset(
                            'assets/qr_code.png', // Tên ảnh của bạn
                            width: 220,
                            height: 220,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Column(
                                  children: [
                                    Icon(
                                      Icons.qr_code_2,
                                      size: 80,
                                      color: Colors.grey,
                                    ),
                                    Text(
                                      "Lỗi tải ảnh QR",
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: Text(
                      "TỔNG CỘNG: ${cart.totalAmount.toInt()}đ",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          onPressed: cart.items.isEmpty ? null : () => _processOrder(cart),
          child: const Text(
            "XÁC NHẬN THANH TOÁN",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
