import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:ban_hat_giong/models/cart_model.dart';
import 'package:ban_hat_giong/screens/checkout_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  Future<void> _deleteOrderHistory(BuildContext context, String orderId) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Xác nhận xoá"),
            content: const Text(
              "Bạn có chắc chắn muốn xoá đơn hàng này khỏi lịch sử không?",
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
      try {
        await FirebaseFirestore.instance
            .collection('order_history')
            .doc(orderId)
            .delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã xoá đơn hàng khỏi lịch sử.")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi khi xoá: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _reorder(BuildContext context, List<dynamic> items) async {
    final cart = Provider.of<CartProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) =>
          const Center(child: CircularProgressIndicator(color: Colors.green)),
    );

    try {
      bool hasStock = false;
      for (var item in items) {
        var productDoc = await FirebaseFirestore.instance
            .collection('products')
            .doc(item['id'])
            .get();
        if (productDoc.exists && (productDoc.data()?['quantity'] ?? 0) > 0) {
          await cart.addItem(
            item['id'],
            (item['price'] as num).toDouble(),
            item['name'],
            item['image'],
          );
          hasStock = true;
        }
      }

      Navigator.pop(context);

      if (hasStock) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CheckoutScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Sản phẩm hiện đã hết hàng!"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Lịch sử mua hàng",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: user == null
          ? const Center(child: Text("Vui lòng đăng nhập để xem lịch sử"))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('order_history')
                  .where('userId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                if (snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Bạn chưa có đơn hàng nào."));
                }

                var docs = snapshot.data!.docs;
                // Sắp xếp đơn mới nhất lên đầu
                docs.sort((a, b) {
                  Timestamp t1 =
                      (a.data() as Map)['timestamp'] ?? Timestamp.now();
                  Timestamp t2 =
                      (b.data() as Map)['timestamp'] ?? Timestamp.now();
                  return t2.compareTo(t1);
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    var items = data['items'] as List<dynamic>;
                    String status = data['status'] ?? 'Chờ xác nhận';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            title: Text(
                              status,
                              style: TextStyle(
                                color: status == 'Hoàn thành'
                                    ? Colors.green
                                    : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.grey,
                              ),
                              onPressed: () =>
                                  _deleteOrderHistory(context, docs[index].id),
                            ),
                          ),
                          const Divider(height: 1),
                          ...items.map(
                            (item) => ListTile(
                              leading: Image.network(
                                item['image'],
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                              ),
                              title: Text(
                                item['name'],
                                style: const TextStyle(fontSize: 14),
                              ),
                              trailing: Text("x${item['quantity']}"),
                            ),
                          ),
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${NumberFormat('#,###').format(data['totalAmount'])}đ",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                ElevatedButton(
                                  //Mua lai
                                  onPressed: () => _reorder(context, items),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                  ),
                                  child: const Text(
                                    "Mua lại",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
