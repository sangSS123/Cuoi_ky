import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'package:ban_hat_giong/models/cart_model.dart';
import 'package:ban_hat_giong/screens/product_detail_screen.dart';
import 'package:ban_hat_giong/screens/welcome_screen.dart';
import 'package:ban_hat_giong/screens/profile_screen.dart';
import 'package:ban_hat_giong/screens/cart_screen.dart';
import 'package:ban_hat_giong/screens/history_screen.dart';

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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        title: _buildSearchField(),
        actions: [_buildCartBadge()],
      ),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          _buildCategorySlider(),
          Expanded(child: _buildProductGrid()),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        onChanged: (v) => setState(() => searchQuery = v.toLowerCase()),
        textAlignVertical: TextAlignVertical.center,
        decoration: const InputDecoration(
          hintText: "Tìm hạt giống...",
          prefixIcon: Icon(Icons.search, color: Colors.green, size: 22),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 10),
        ),
      ),
    );
  }

  Widget _buildCartBadge() {
    return Consumer<CartProvider>(
      builder: (context, cart, child) => IconButton(
        icon: Badge(
          label: Text(cart.itemCount.toString()),
          isLabelVisible: cart.itemCount > 0,
          child: const Icon(Icons.shopping_cart, color: Colors.white),
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CartScreen()),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          String name = "Người dùng";
          String role = "user";
          if (snapshot.hasData && snapshot.data!.exists) {
            var data = snapshot.data!.data() as Map<String, dynamic>;
            name = data['fullname'] ?? "Người dùng";
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
                currentAccountPicture: OverflowBox(
                  minWidth: 0,
                  minHeight: 0,
                  maxWidth: double.infinity,
                  maxHeight: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 2.5),
                        ),
                      ),
                      ClipOval(
                        child: Image.asset(
                          'assets/user_avatar.png',
                          width: 113,
                          height: 113,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _drawerTile(
                Icons.home,
                "Trang chủ",
                () => Navigator.pop(context),
              ),
              _drawerTile(
                Icons.person,
                "Hồ sơ cá nhân",
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const ProfileScreen()),
                ),
              ),
              _drawerTile(
                Icons.history,
                "Lịch sử mua hàng",
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const HistoryScreen()),
                ),
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
                _drawerTile(
                  Icons.inventory,
                  "Quản lý mặt hàng",
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => const AdminProductList()),
                  ),
                  color: Colors.orange,
                ),
                _drawerTile(
                  Icons.assignment,
                  "Quản lý đơn hàng",
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => const AdminOrdersScreen(),
                    ),
                  ),
                  color: Colors.orange,
                ),
                _drawerTile(
                  Icons.people,
                  "Quản lý người dùng",
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => const AdminUserManagement(),
                    ),
                  ),
                  color: Colors.blue,
                ),
                _drawerTile(
                  Icons.bar_chart,
                  "Thống kê doanh thu",
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => const RevenueStatsScreen(),
                    ),
                  ),
                  color: Colors.purple,
                ),
              ],
              const Divider(),
              _drawerTile(Icons.logout, "Đăng xuất", () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (c) => const WelcomeScreen()),
                );
              }, color: Colors.red),
            ],
          );
        },
      ),
    );
  }

  Widget _drawerTile(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color color = Colors.green,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      onTap: onTap,
    );
  }

  Widget _buildCategorySlider() {
    return Container(
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
              onSelected: (val) =>
                  setState(() => selectedCategory = categories[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        var docs = snapshot.data!.docs.where((d) {
          var data = d.data() as Map<String, dynamic>;
          String name = (data['name'] ?? "").toString().toLowerCase();
          return name.contains(searchQuery) &&
              (selectedCategory == "Tất cả" ||
                  formatCategory(data['id_category']) == selectedCategory);
        }).toList();

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.72,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            bool isOutOfStock = (data['quantity'] ?? 0) <= 0;

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => ProductDetailScreen(
                            product: {...data, 'id': docs[index].id},
                          ),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(15),
                        ),
                        child: Stack(
                          children: [
                            Image.network(
                              data['image'] ?? "",
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            if (isOutOfStock)
                              Container(
                                color: Colors.black45,
                                child: const Center(
                                  child: Text(
                                    "HẾT HÀNG",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Text(
                          data['name'] ?? "",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${data['price']}đ",
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isOutOfStock
                                  ? Colors.grey
                                  : Colors.green,
                              shape: const StadiumBorder(),
                              elevation: 0,
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
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Đã thêm ${data['name']}',
                                        ),
                                        duration: const Duration(seconds: 1),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  },
                            child: Text(
                              isOutOfStock ? "HẾT" : "MUA",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
    );
  }
}
