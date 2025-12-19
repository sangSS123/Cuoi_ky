import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ban_hat_giong/models/cart_model.dart';

class ProductDetailScreen extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    // Kiểm tra xem còn hàng không
    bool isOutOfStock = (product['quantity'] ?? 0) <= 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(product['name'] ?? "Chi tiết sản phẩm"),
        backgroundColor: Colors.green,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    product['image'] ?? "",
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  product['name'] ?? "",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${product['price']}đ",
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(height: 30),
                const Text(
                  "MÔ TẢ SẢN PHẨM",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  product['description'] ?? "Chưa có mô tả cho sản phẩm này.",
                ),
                const SizedBox(
                  height: 100,
                ), // Khoảng trống để không bị nút đè lên chữ
              ],
            ),
          ),

          // NÚT MUA NGAY CỐ ĐỊNH Ở DƯỚI CÙNG
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isOutOfStock ? Colors.grey : Colors.green,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: isOutOfStock
                  ? null
                  : () {
                      // LOGIC THÊM VÀO GIỎ HÀNG (Sửa lỗi bạn đang gặp)
                      context.read<CartProvider>().addItem(
                        product['id'], // ID lấy từ map đã thêm ở Bước 1
                        (product['price'] as num).toDouble(),
                        product['name'],
                        product['image'],
                      );

                      // Hiển thị thông báo
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Đã thêm ${product['name']} vào giỏ hàng!",
                          ),
                          duration: const Duration(seconds: 2),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
              child: Text(
                isOutOfStock ? "HẾT HÀNG" : "MUA NGAY",
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
