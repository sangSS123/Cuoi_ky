import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

// Import các model và screen
import 'package:ban_hat_giong/models/cart_model.dart';
import 'package:ban_hat_giong/screens/product_detail_screen.dart';
import 'package:ban_hat_giong/screens/welcome_screen.dart';
import 'package:ban_hat_giong/screens/profile_screen.dart';
import 'package:ban_hat_giong/screens/cart_screen.dart';
import 'package:ban_hat_giong/screens/history_screen.dart';

// Các màn hình quản lý dành cho Admin
import 'package:ban_hat_giong/screens/admin/admin_product_list.dart';
import 'package:ban_hat_giong/screens/admin/admin_user_management.dart';
import 'package:ban_hat_giong/screens/admin/admin_orders_screen.dart';
import 'package:ban_hat_giong/screens/admin/revenue_stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = FirebaseAuth.instance.currentUser;
  String searchQuery = "";
  String selectedCategory = "Tất cả";
  final List<String> categories = ["Tất cả", "Rau", "Cây ăn quả", "Hoa"];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<CartProvider>().fetchAndSetCart());
  }

  String formatCategory(String? id) {
    if (id == 'cay_an_la') return 'Rau';
    if (id == 'cay_an_qua') return 'Cây ăn quả';
    return 'Hoa';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        title: Container(
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            onChanged: (v) => setState(() => searchQuery = v.toLowerCase()),
            textAlignVertical:
                TextAlignVertical.center, // Căn giữa chữ theo chiều dọc
            decoration: const InputDecoration(
              hintText: "Tìm hạt giống...",
              hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
              prefixIcon: Icon(Icons.search, color: Colors.green, size: 20),
              border: InputBorder.none,
              // Điều chỉnh padding để không bị lệch
              contentPadding: EdgeInsets.symmetric(vertical: 8),
              isDense: true,
            ),
          ),
        ),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, child) => IconButton(
              icon: Badge(
                label: Text(
                  cart.itemCount.toString(),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                isLabelVisible: cart.itemCount > 0,
                backgroundColor: Colors.red,
                alignment: const AlignmentDirectional(10, -8),
                child: const Icon(
                  Icons.shopping_cart,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartScreen()),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      drawer: Drawer(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            String name = "Người dùng";
            String avatarUrl = "";
            String role = "user";

            if (snapshot.hasData && snapshot.data!.exists) {
              var data = snapshot.data!.data() as Map<String, dynamic>;
              name = data['fullname'] ?? "Người dùng";
              avatarUrl = data['avatar'] ?? "";
              role = data['role'] ?? "user";
            }

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(color: Colors.green),
                  accountName: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  accountEmail: Text(user?.email ?? ""),
                  currentAccountPicture: Center(
                    child: Container(
                      width: 75,
                      height: 75,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.black, width: 3),
                      ),
                      child: OverflowBox(
                        maxWidth: double.infinity,
                        maxHeight: double.infinity,
                        child: ClipOval(
                          child: avatarUrl.isNotEmpty
                              ? Image.network(
                                  avatarUrl,
                                  width: 95,
                                  height: 95,
                                  fit: BoxFit.cover,
                                )
                              : Image.asset(
                                  'assets/user_avatar.png',
                                  width: 95,
                                  height: 95,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.home, color: Colors.green),
                  title: const Text("Trang chủ"),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.account_circle,
                    color: Colors.green,
                  ),
                  title: const Text("Hồ sơ cá nhân"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history, color: Colors.green),
                  title: const Text("Lịch sử mua hàng"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HistoryScreen(),
                      ),
                    );
                  },
                ),
                if (role == 'admin') ...[
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.only(left: 16, top: 10, bottom: 5),
                    child: Text(
                      "QUẢN TRỊ VIÊN",
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.inventory, color: Colors.orange),
                    title: const Text("Quản lý mặt hàng"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminProductList(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.assignment, color: Colors.orange),
                    title: const Text("Quản lý đơn hàng"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminOrdersScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.people, color: Colors.blue),
                    title: const Text("Quản lý người dùng"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminUserManagement(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.bar_chart, color: Colors.purple),
                    title: const Text("Thống kê doanh thu"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RevenueStatsScreen(),
                        ),
                      );
                    },
                  ),
                ],
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text("Đăng xuất"),
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    if (!mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WelcomeScreen(),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                bool isSelected = selectedCategory == categories[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(categories[index]),
                    selected: isSelected,
                    selectedColor: Colors.green,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                    onSelected: (bool selected) =>
                        setState(() => selectedCategory = categories[index]),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                var docs = snapshot.data!.docs.where((d) {
                  var data = d.data() as Map<String, dynamic>;
                  String name = (data['name'] ?? "").toString().toLowerCase();
                  String categoryName = formatCategory(data['id_category']);
                  return name.contains(searchQuery) &&
                      (selectedCategory == "Tất cả" ||
                          categoryName == selectedCategory);
                }).toList();

                return GridView.builder(
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.58,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    bool isOutOfStock = (data['quantity'] ?? 0) <= 0;

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductDetailScreen(
                                    product: {...data, 'id': docs[index].id},
                                  ),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12),
                                      ),
                                      child: Image.network(
                                        data['image'] ?? "",
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        errorBuilder: (c, e, s) => const Icon(
                                          Icons.image_not_supported,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Column(
                                      children: [
                                        Text(
                                          data['name'] ?? "",
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          "${data['price']}đ",
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isOutOfStock
                                  ? Colors.grey
                                  : Colors.green,
                              minimumSize: const Size(double.infinity, 32),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  bottom: Radius.circular(12),
                                ),
                              ),
                            ),
                            onPressed: isOutOfStock
                                ? null
                                : () {
                                    context.read<CartProvider>().addItem(
                                      docs[index].id,
                                      (data['price'] as num).toDouble(),
                                      data['name'],
                                      data['image'],
                                    );
                                    ScaffoldMessenger.of(
                                      context,
                                    ).hideCurrentSnackBar();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Đã thêm "${data['name']}" vào giỏ',
                                        ),
                                        duration: const Duration(seconds: 1),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  },
                            child: Text(
                              isOutOfStock ? "HẾT" : "MUA",
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
