import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'package:ban_hat_giong/models/cart_model.dart';
import 'package:ban_hat_giong/screens/welcome_screen.dart';
import 'package:ban_hat_giong/screens/home_screen.dart';
import 'package:ban_hat_giong/screens/profile_screen.dart';
import 'package:ban_hat_giong/screens/cart_screen.dart';
import 'package:ban_hat_giong/screens/history_screen.dart';
import 'package:ban_hat_giong/screens/admin/admin_product_list.dart';
import 'package:ban_hat_giong/screens/admin/edit_product_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      if (kDebugMode) print('✅ Firebase initialized successfully.');
    } else {
      if (kDebugMode) print('ℹ️ Firebase already initialized.');
    }
  } catch (e) {
    if (kDebugMode) print('❌ Firebase initialization error: $e');
  }

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => CartProvider())],
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
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: false,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),
      home: const WelcomeScreen(),
      routes: {
        '/welcome': (_) => const WelcomeScreen(),
        '/home': (_) => const HomeScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/cart': (_) => const CartScreen(),
        '/history': (_) => const HistoryScreen(),
        '/admin_products': (_) => const AdminProductList(),
        '/edit_product': (_) => const EditProductScreen(),
      },
      onUnknownRoute: (_) =>
          MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }
}
