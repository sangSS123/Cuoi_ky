import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  // --- GIỮ NGUYÊN LOGIC VALIDATE ---
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w\-\.]+@([\w\-\.]+\.)+[\w\-\.]{2,4}$').hasMatch(email);
  }

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

  // --- GIỮ NGUYÊN LOGIC ĐĂNG KÝ ---
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    _showLoading();

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          )
          .timeout(const Duration(seconds: 15));

      final user = userCredential.user;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'fullname': _fullnameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'role': 'user',
          'isLocked': false,
          'avatar': '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      _hideLoading();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đăng ký thành công!"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // Quay lại trang Login
    } on FirebaseAuthException catch (e) {
      _hideLoading();
      String msg = "Lỗi đăng ký";
      if (e.code == 'email-already-in-use') msg = "Email này đã được sử dụng";
      if (e.code == 'weak-password') msg = "Mật khẩu quá yếu";
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    } catch (e) {
      _hideLoading();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
      );
    }
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
          child: Stack(
            children: [
              // LỚP 1: Nội dung chính
              Column(
                children: [
                  const SizedBox(height: 60),
                  const Icon(Icons.eco, size: 70, color: Colors.white),
                  const Text(
                    "Đăng ký tài khoản",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "Hạt giống xanh - Cuộc sống lành",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 30),

                  // Khung nhập liệu
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 30,
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
                          children: [
                            const Text(
                              "Đăng Ký",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 25),

                            _buildTextField(
                              controller: _fullnameController,
                              label: "Họ và tên",
                              icon: Icons.person_outline,
                              validator: (v) => (v == null || v.isEmpty)
                                  ? "Vui lòng nhập họ tên"
                                  : null,
                            ),
                            const SizedBox(height: 15),

                            _buildTextField(
                              controller: _emailController,
                              label: "Email",
                              icon: Icons.email_outlined,
                              type: TextInputType.emailAddress,
                              validator: (v) => !_isValidEmail(v!)
                                  ? "Email không hợp lệ"
                                  : null,
                            ),
                            const SizedBox(height: 15),

                            _buildTextField(
                              controller: _phoneController,
                              label: "Số điện thoại",
                              icon: Icons.phone_outlined,
                              type: TextInputType.phone,
                              validator: (v) => (v == null || v.length < 10)
                                  ? "SĐT không hợp lệ"
                                  : null,
                            ),
                            const SizedBox(height: 15),

                            _buildTextField(
                              controller: _passwordController,
                              label: "Mật khẩu",
                              icon: Icons.lock_outline,
                              isObscure: true,
                              validator: (v) => (v == null || v.length < 6)
                                  ? "Tối thiểu 6 ký tự"
                                  : null,
                            ),
                            const SizedBox(height: 35),

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
                                onPressed: _register,
                                child: const Text(
                                  "XÁC NHẬN ĐĂNG KÝ",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
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
                ],
              ),

              // LỚP 2: Nút Back
              Positioned(
                top: 10,
                left: 10,
                child: SafeArea(
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Hàm Helper tạo TextField trang trí
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isObscure = false,
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.green),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
      ),
      validator: validator,
    );
  }
}
