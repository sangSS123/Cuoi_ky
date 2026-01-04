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
            .collection('revenue_reports')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Chưa có dữ liệu doanh thu"));
          }

          double totalRevenue = 0;
          int totalOrders = snapshot.data!.docs.length;
          Map<String, double> dailyStats = {};

          for (var doc in snapshot.data!.docs) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            double amount = (data['amount'] as num? ?? 0).toDouble();
            totalRevenue += amount;

            Timestamp? timestamp = data['timestamp'] as Timestamp?;
            if (timestamp != null) {
              String dateKey = DateFormat(
                'dd/MM/yyyy',
              ).format(timestamp.toDate());
              dailyStats[dateKey] = (dailyStats[dateKey] ?? 0) + amount;
            }
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border(
                    bottom: BorderSide(color: Colors.green.shade100),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      "TỔNG DOANH THU",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${NumberFormat('#,###').format(totalRevenue)}đ",
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.shopping_cart_checkout,
                          size: 20,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          "Tổng đơn hàng: ",
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        Text(
                          "$totalOrders đơn",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      "Doanh thu theo ngày",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView.builder(
                  itemCount: dailyStats.length,
                  itemBuilder: (context, index) {
                    String date = dailyStats.keys.elementAt(index);
                    double dailyAmount = dailyStats[date]!;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 5,
                      ),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Icon(
                            Icons.trending_up,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          date,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: Text(
                          "${NumberFormat('#,###').format(dailyAmount)}đ",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
