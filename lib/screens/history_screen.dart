import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:ban_hat_giong/models/cart_model.dart';
import 'package:ban_hat_giong/screens/checkout_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  // --- HÀM XỬ LÝ XOÁ ĐƠN HÀNG ---
  Future<void> _deleteOrder(BuildContext context, String orderId) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Xác nhận xoá"),
            content: const Text(
              "Bạn có chắc chắn muốn xoá đơn hàng này không?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text("HỦY"),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text("XOÁ", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      await FirebaseFirestore.instance
          .collection('order_history')
          .doc(orderId)
          .delete();
    }
  }

  // --- HÀM MUA LẠI CÓ KIỂM TRA TỒN KHO ---
  Future<void> _reorder(BuildContext context, List<dynamic> items) async {
    final cart = Provider.of<CartProvider>(context, listen: false);

    // Hiện Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) =>
          const Center(child: CircularProgressIndicator(color: Colors.green)),
    );

    try {
      List<String> outOfStockItems = [];
      bool hasAtLeastOneItem = false;

      // 1. Kiểm tra từng món trong đơn hàng cũ xem còn hàng không
      for (var item in items) {
        var productDoc = await FirebaseFirestore.instance
            .collection('products')
            .doc(item['id'])
            .get();

        if (productDoc.exists) {
          int currentStock = productDoc.data()?['quantity'] ?? 0;

          if (currentStock > 0) {
            // Còn hàng -> Thêm vào giỏ (số lượng lấy theo đơn cũ hoặc số lượng còn lại trong kho)
            int quantityToAdd = (item['quantity'] as int) > currentStock
                ? currentStock
                : item['quantity'];

            for (int i = 0; i < quantityToAdd; i++) {
              await cart.addItem(
                item['id'],
                (item['price'] as num).toDouble(),
                item['name'],
                item['image'],
              );
            }
            hasAtLeastOneItem = true;
          } else {
            outOfStockItems.add(item['name']);
          }
        } else {
          outOfStockItems.add("${item['name']} (Đã ngừng bán)");
        }
      }

      if (!context.mounted) return;
      Navigator.pop(context); // Đóng Loading

      // 2. Xử lý kết quả kiểm tra
      if (!hasAtLeastOneItem) {
        // Trường hợp tất cả đều hết hàng
        _showError(
          context,
          "Rất tiếc, tất cả sản phẩm trong đơn này hiện đã hết hàng!",
        );
      } else {
        // Nếu có món hết, có món còn
        if (outOfStockItems.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Lưu ý: Một số món (${outOfStockItems.join(', ')}) đã hết hàng nên không được thêm vào.",
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }

        // 3. Chuyển sang trang thanh toán
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CheckoutScreen()),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      _showError(context, "Lỗi khi kiểm tra kho: $e");
    }
  }

  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Lịch sử mua hàng"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: user == null
          ? const Center(child: Text("Vui lòng đăng nhập"))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('order_history')
                  .where('userId', isEqualTo: user.uid)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                if (snapshot.data!.docs.isEmpty)
                  return const Center(
                    child: Text("Bạn chưa mua hàng lần nào."),
                  );

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var data =
                        snapshot.data!.docs[index].data()
                            as Map<String, dynamic>;
                    var items = data['items'] as List<dynamic>;
                    var timestamp = data['timestamp'] as Timestamp?;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildStatusChip(
                                  data['status'] ?? 'Chờ xác nhận',
                                ),
                                IconButton(
                                  onPressed: () => _deleteOrder(
                                    context,
                                    snapshot.data!.docs[index].id,
                                  ),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            ...items.map(
                              (item) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Image.network(
                                  item['image'],
                                  width: 35,
                                ),
                                title: Text(
                                  item['name'],
                                  style: const TextStyle(fontSize: 13),
                                ),
                                trailing: Text("x${item['quantity']}"),
                              ),
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  timestamp != null
                                      ? DateFormat(
                                          'dd/MM/yy HH:mm',
                                        ).format(timestamp.toDate())
                                      : '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _reorder(context, items),
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text(
                                    "Mua lại",
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade700,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                Text(
                                  "${data['totalAmount'].toInt()}đ",
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status == 'Đã hoàn thành' ? Colors.green : Colors.orange,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status,
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
    );
  }
}
