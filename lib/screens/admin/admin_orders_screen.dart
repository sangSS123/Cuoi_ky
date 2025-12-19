import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  // Hàm cập nhật trạng thái đơn hàng lên Firestore
  Future<void> _updateOrderStatus(
    BuildContext context,
    String orderId,
    String newStatus,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('order_history')
          .doc(orderId)
          .update({'status': newStatus});

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Đã chuyển trạng thái sang: $newStatus"),
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
        // Lấy tất cả đơn hàng từ tất cả người dùng, sắp xếp mới nhất lên đầu
        stream: FirebaseFirestore.instance
            .collection('order_history')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Hiện chưa có đơn hàng nào."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var orderDoc = snapshot.data!.docs[index];
              var orderData = orderDoc.data() as Map<String, dynamic>;
              var items = orderData['items'] as List<dynamic>;
              var timestamp = orderData['timestamp'] as Timestamp?;
              String currentStatus = orderData['status'] ?? 'Chờ xác nhận';

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(
                      currentStatus,
                    ).withOpacity(0.2),
                    child: Icon(
                      Icons.receipt_long,
                      color: _getStatusColor(currentStatus),
                    ),
                  ),
                  title: Text(
                    "Đơn: ...${orderDoc.id.substring(orderDoc.id.length - 6)}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Tổng: ${orderData['totalAmount'].toInt()}đ - $currentStatus",
                    style: TextStyle(
                      color: _getStatusColor(currentStatus),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          const Text(
                            "THÔNG TIN KHÁCH HÀNG",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "SĐT: ${orderData['phone']}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text("Địa chỉ: ${orderData['address']}"),
                          Text(
                            "Thời gian: ${timestamp != null ? DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate()) : 'Không rõ'}",
                          ),
                          const SizedBox(height: 15),

                          const Text(
                            "CHI TIẾT SẢN PHẨM",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ...items.map(
                            (item) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Image.network(
                                item['image'],
                                width: 30,
                                height: 30,
                                fit: BoxFit.cover,
                              ),
                              title: Text(
                                item['name'],
                                style: const TextStyle(fontSize: 13),
                              ),
                              trailing: Text("x${item['quantity']}"),
                            ),
                          ),

                          const Divider(),
                          const Text(
                            "CẬP NHẬT TRẠNG THÁI",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
                                ),
                                const SizedBox(width: 8),
                                _statusBtn(
                                  context,
                                  orderDoc.id,
                                  "Hoàn thành",
                                  Colors.green,
                                ),
                                const SizedBox(width: 8),
                                _statusBtn(
                                  context,
                                  orderDoc.id,
                                  "Đã hủy",
                                  Colors.red,
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

  // Widget nút bấm thay đổi trạng thái
  Widget _statusBtn(
    BuildContext context,
    String id,
    String status,
    Color color,
  ) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: () => _updateOrderStatus(context, id, status),
      child: Text(status, style: const TextStyle(fontSize: 12)),
    );
  }

  // Hàm trả về màu sắc tương ứng với trạng thái
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Đang giao':
        return Colors.blue;
      case 'Hoàn thành':
        return Colors.green;
      case 'Đã hủy':
        return Colors.red;
      default:
        return Colors.orange; // Chờ xác nhận
    }
  }
}
