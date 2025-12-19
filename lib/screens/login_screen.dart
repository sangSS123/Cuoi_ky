import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isObscure = true;

  // --- GIỮ NGUYÊN LOGIC LOADING ---
  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }

  void _hideLoading() {
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  // --- GIỮ NGUYÊN LOGIC LOGIN ---
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    _showLoading();

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          )
          .timeout(const Duration(seconds: 15));

      final user = userCredential.user;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          if (userData['isLocked'] == true) {
            await FirebaseAuth.instance.signOut();
            _hideLoading();
            _showError("Tài khoản của bạn đã bị khóa!");
            return;
          }
        }
      }

      _hideLoading();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      _hideLoading();
      _showError(
        e.code == 'user-not-found'
            ? "Email không tồn tại"
            : "Sai mật khẩu hoặc lỗi đăng nhập",
      );
    } catch (e) {
      _hideLoading();
      _showError("Đã xảy ra lỗi: $e");
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.green.shade700, Colors.green.shade400],
            ),
          ),
          // SỬ DỤNG STACK ĐỂ ĐẶT NÚT BACK LÊN TRÊN NỀN
          child: Stack(
            children: [
              // LỚP 1: Nội dung chính (Header + Form)
              Column(
                children: [
                  // Giảm khoảng cách trên cùng xuống một chút vì đã có nút back
                  const SizedBox(height: 60),
                  const Icon(Icons.eco, size: 80, color: Colors.white),
                  const SizedBox(height: 10),
                  const Text(
                    "Chào mừng trở lại!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "Đăng nhập để tiếp tục mua sắm",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 40),

                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 40,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40),
                        ),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Đăng Nhập",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 30),

                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                hintText: 'example@gmail.com',
                                prefixIcon: const Icon(
                                  Icons.email_outlined,
                                  color: Colors.green,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                              ),
                              validator: (v) =>
                                  (v!.isEmpty) ? "Vui lòng nhập email" : null,
                            ),
                            const SizedBox(height: 20),

                            TextFormField(
                              controller: _passwordController,
                              obscureText: _isObscure,
                              decoration: InputDecoration(
                                labelText: 'Mật khẩu',
                                prefixIcon: const Icon(
                                  Icons.lock_outline,
                                  color: Colors.green,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isObscure
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () =>
                                      setState(() => _isObscure = !_isObscure),
                                ),
                              ),
                              validator: (v) => (v!.isEmpty)
                                  ? "Vui lòng nhập mật khẩu"
                                  : null,
                            ),
                            const SizedBox(height: 40),

                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade600,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 5,
                                ),
                                onPressed: _login,
                                child: const Text(
                                  "ĐĂNG NHẬP",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            // ĐÃ XÓA NÚT TEXT BUTTON Ở ĐÂY
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // LỚP 2: Nút Back ở góc trên bên trái
              Positioned(
                top: 10,
                left: 10,
                child: SafeArea(
                  // Đảm bảo không bị tai thỏ che
                  child: IconButton(
                    // Sử dụng icon mũi tên hiện đại, màu trắng cho nổi bật
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () =>
                        Navigator.pop(context), // Quay lại màn hình trước
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
