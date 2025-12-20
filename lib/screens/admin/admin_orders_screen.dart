import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  // HÀM CẬP NHẬT: Giữ nguyên tên hàm, thêm logic ghi bảng revenue_reports
  Future<void> _updateOrderStatus(
    BuildContext context,
    String orderId,
    String newStatus,
    double amount, // Thêm tham số amount để lấy số tiền đơn hàng
  ) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      // 1. Cập nhật trạng thái trong 'order_history' (Ảnh 1)
      final orderRef = FirebaseFirestore.instance
          .collection('order_history')
          .doc(orderId);
      batch.update(orderRef, {'status': newStatus});

      // 2. LOGIC QUAN TRỌNG: Nếu là 'Hoàn thành', ghi vào 'revenue_reports' (Ảnh 2)
      if (newStatus == 'Hoàn thành') {
        final revenueRef = FirebaseFirestore.instance
            .collection('revenue_reports')
            .doc(orderId);
        batch.set(revenueRef, {
          'orderId': orderId,
          'amount': amount,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit(); // Thực hiện ghi cả 2 bảng cùng lúc

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'Hoàn thành'
                ? "Đã hoàn thành và cộng $amountđ vào doanh thu!"
                : "Đã chuyển trạng thái sang: $newStatus",
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Lỗi khi cập nhật: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý đơn hàng hệ thống"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('order_history')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Không có đơn hàng nào"));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final orderDoc = snapshot.data!.docs[index];
              final data = orderDoc.data() as Map<String, dynamic>;

              final status = data['status'] ?? 'Chờ xác nhận';
              final totalAmount = (data['totalAmount'] as num? ?? 0).toDouble();
              final items = (data['items'] as List<dynamic>? ?? []);
              final timestamp =
                  (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

              return Card(
                margin: const EdgeInsets.all(10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 3,
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(status).withOpacity(0.2),
                    child: Icon(
                      Icons.shopping_bag,
                      color: _getStatusColor(status),
                    ),
                  ),
                  title: Text(
                    "Đơn hàng: ${orderDoc.id.substring(0, 8)}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "${DateFormat('dd/MM/yyyy HH:mm').format(timestamp)} - ${NumberFormat('#,###').format(totalAmount)}đ",
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...items.map(
                            (item) =>
                                Text("• ${item['name']} x${item['quantity']}"),
                          ),
                          const Divider(),
                          Text("Địa chỉ: ${data['address'] ?? 'N/A'}"),
                          Text("SĐT: ${data['phone'] ?? 'N/A'}"),
                          const SizedBox(height: 10),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _statusBtn(
                                  context,
                                  orderDoc.id,
                                  "Đang giao",
                                  Colors.blue,
                                  totalAmount,
                                ),
                                const SizedBox(width: 5),
                                _statusBtn(
                                  context,
                                  orderDoc.id,
                                  "Hoàn thành",
                                  Colors.green,
                                  totalAmount,
                                ),
                                const SizedBox(width: 5),
                                _statusBtn(
                                  context,
                                  orderDoc.id,
                                  "Đã hủy",
                                  Colors.red,
                                  totalAmount,
                                ),
                              ],
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

  Widget _statusBtn(
    BuildContext context,
    String id,
    String status,
    Color color,
    double amount,
  ) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: () => _updateOrderStatus(context, id, status, amount),
      child: Text(status, style: const TextStyle(fontSize: 12)),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Đang giao':
        return Colors.blue;
      case 'Hoàn thành':
        return Colors.green;
      case 'Đã hủy':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}
