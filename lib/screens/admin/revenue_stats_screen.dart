import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RevenueStatsScreen extends StatelessWidget {
  const RevenueStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thống kê doanh thu"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('order_history')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Chưa có dữ liệu đơn hàng"));
          }

          final docs = snapshot.data!.docs;

          // Tính toán số liệu
          double totalRevenue = 0;
          double todayRevenue = 0;
          int completedOrders = 0;
          int pendingOrders = 0;
          int canceledOrders = 0;

          DateTime now = DateTime.now();

          for (var doc in docs) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            double amount = (data['totalAmount'] as num).toDouble();
            String status = data['status'] ?? 'Chờ xác nhận';
            Timestamp? ts = data['timestamp'] as Timestamp?;

            if (status == 'Hoàn thành') {
              totalRevenue += amount;
              completedOrders++;

              // Kiểm tra nếu là doanh thu hôm nay
              if (ts != null) {
                DateTime date = ts.toDate();
                if (date.day == now.day &&
                    date.month == now.month &&
                    date.year == now.year) {
                  todayRevenue += amount;
                }
              }
            } else if (status == 'Đã hủy') {
              canceledOrders++;
            } else {
              pendingOrders++;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildSummaryCard(
                  "TỔNG DOANH THU",
                  "${NumberFormat('#,###').format(totalRevenue)}đ",
                  Icons.monetization_on,
                  Colors.green,
                ),
                const SizedBox(height: 15),
                _buildSummaryCard(
                  "DOANH THU HÔM NAY",
                  "${NumberFormat('#,###').format(todayRevenue)}đ",
                  Icons.today,
                  Colors.blue,
                ),
                const SizedBox(height: 25),
                const Text(
                  "Trạng thái đơn hàng",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    _buildSmallStatCard(
                      "Hoàn thành",
                      completedOrders.toString(),
                      Colors.green,
                    ),
                    _buildSmallStatCard(
                      "Đang xử lý",
                      pendingOrders.toString(),
                      Colors.orange,
                    ),
                    _buildSmallStatCard(
                      "Đã hủy",
                      canceledOrders.toString(),
                      Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                // Có thể thêm danh sách các đơn hàng thành công gần đây ở đây
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color,
            radius: 30,
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStatCard(String label, String value, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
