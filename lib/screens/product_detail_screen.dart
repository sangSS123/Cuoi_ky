import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ban_hat_giong/models/cart_model.dart';

class ProductDetailScreen extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    // Kiểm tra xem còn hàng không
    int stock = product['quantity'] ?? 0;
    bool isOutOfStock = stock <= 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Chi tiết hạt giống"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 300,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          image: DecorationImage(
                            image: NetworkImage(product['image'] ?? ""),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      if (isOutOfStock)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black26,
                            child: const Center(
                              child: Text(
                                "TẠM HẾT HÀNG",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  backgroundColor: Colors.black45,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  //Phần thông tin chi tiết
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start, //Trục chéo( Trai sang phai)
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                product['name'] ?? "Tên sản phẩm",
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            // Hiển thị số lượng còn lại
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "Kho: $stock",
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Giá tiền
                        Text(
                          "${product['price']}đ",
                          style: const TextStyle(
                            fontSize: 26,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Divider(height: 30),

                        // Mô tả sản phẩm
                        const Text(
                          "Mô tả sản phẩm",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          product['description'] ??
                              "Chưa có mô tả cho sản phẩm này.",
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black54,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isOutOfStock ? Colors.grey : Colors.green,
            minimumSize: const Size(double.infinity, 55),
            shape:
                RoundedRectangleBorder //Hình chữ nhật bo góc
                (borderRadius: BorderRadius.circular(15)),
            elevation: 5,
          ),
          onPressed: isOutOfStock
              ? null
              : () {
                  context.read<CartProvider>().addItem(
                    product['id'],
                    (product['price'] as num).toDouble(),
                    product['name'],
                    product['image'],
                  );

                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 10),
                          Text("Đã thêm ${product['name']} vào giỏ!"),
                        ],
                      ),
                      duration: const Duration(seconds: 2),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
          child: Text(
            isOutOfStock ? "TẠM HẾT HÀNG" : "THÊM VÀO GIỎ HÀNG",
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
