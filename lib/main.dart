import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// Import Firebase Options (File sinh ra khi bạn cấu hình FlutterFire)
import 'firebase_options.dart';

// Import Models
import 'package:ban_hat_giong/models/cart_model.dart';

// Import Screens (Người dùng)
import 'package:ban_hat_giong/screens/welcome_screen.dart';
import 'package:ban_hat_giong/screens/home_screen.dart';
import 'package:ban_hat_giong/screens/profile_screen.dart';
import 'package:ban_hat_giong/screens/cart_screen.dart';
import 'package:ban_hat_giong/screens/history_screen.dart';

// Import Screens (Admin) - Đảm bảo đường dẫn này đúng với cấu thư mục của bạn
import 'package:ban_hat_giong/screens/admin/admin_product_list.dart';
import 'package:ban_hat_giong/screens/admin/edit_product_screen.dart';

void main() async {
  // Đảm bảo các dịch vụ của Flutter được khởi tạo trước khi gọi Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase với cấu hình mặc định
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    // Cấu hình MultiProvider nếu bạn có nhiều Provider, hiện tại là CartProvider
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (ctx) => CartProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bán Hạt Giống',

      // Cấu hình Theme cho toàn bộ ứng dụng
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3:
            false, // Sử dụng Material 2 để giao diện ổn định với code cũ
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),

      // Màn hình khởi đầu (Thường là Welcome hoặc Login)
      home: const WelcomeScreen(),

      // Định nghĩa các Routes để điều hướng dễ dàng bằng tên
      routes: {
        '/welcome': (ctx) => const WelcomeScreen(),
        '/home': (ctx) => const HomeScreen(),
        '/profile': (ctx) => const ProfileScreen(),
        '/cart': (ctx) => const CartScreen(),
        '/history': (ctx) => const HistoryScreen(),

        // Routes dành cho Admin
        '/admin_products': (ctx) => const AdminProductList(),
        '/edit_product': (ctx) => const EditProductScreen(),
      },

      // Xử lý lỗi khi điều hướng đến route không tồn tại
      onUnknownRoute: (settings) {
        return MaterialPageRoute(builder: (ctx) => const HomeScreen());
      },
    );
  }
}
