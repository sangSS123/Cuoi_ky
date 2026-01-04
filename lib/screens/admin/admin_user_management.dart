import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUserManagement extends StatefulWidget {
  const AdminUserManagement({super.key});

  @override
  State<AdminUserManagement> createState() => _AdminUserManagementState();
}

class _AdminUserManagementState extends State<AdminUserManagement> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Widget _buildOverflowAvatar(String? avatarUrl, {double size = 50}) {
    double frameSize = size;
    double catSize = size * 1.3;

    return SizedBox(
      width: catSize,
      height: catSize,
      child: Center(
        child: Container(
          width: frameSize,
          height: frameSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 2.5),
          ),
          child: OverflowBox(
            maxWidth: catSize,
            maxHeight: catSize,
            child: ClipOval(
              child: (avatarUrl != null && avatarUrl.isNotEmpty)
                  ? Image.network(
                      avatarUrl,
                      width: catSize,
                      height: catSize,
                      fit: BoxFit.cover,
                    )
                  : Image.asset(
                      'assets/user_avatar.png',
                      width: catSize,
                      height: catSize,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  void _deleteUser(String userId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận"),
        content: const Text("Bạn có chắc chắn muốn xóa người dùng này?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () {
              _firestore.collection('users').doc(userId).delete();
              Navigator.pop(ctx);
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _editUser(String userId, Map<String, dynamic> currentData) {
    TextEditingController nameController = TextEditingController(
      text: currentData['fullname'],
    );
    String selectedRole = currentData['role'] ?? 'user';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Sửa thông tin & Phân quyền"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Họ tên"),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(labelText: "Vai trò"),
                items: const [
                  DropdownMenuItem(
                    value: 'user',
                    child: Text("Người dùng (user)"),
                  ),
                  DropdownMenuItem(
                    value: 'admin',
                    child: Text("Quản trị viên (admin)"),
                  ),
                ],
                onChanged: (val) => setDialogState(() => selectedRole = val!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () {
                _firestore.collection('users').doc(userId).update({
                  'fullname': nameController.text,
                  'role': selectedRole,
                });
                Navigator.pop(ctx);
              },
              child: const Text("Lưu"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý người dùng"),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          var users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var userData = users[index].data() as Map<String, dynamic>;
              String userId = users[index].id;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),
                  leading: _buildOverflowAvatar(userData['avatar'], size: 55),
                  title: Text(
                    userData['fullname'] ?? "Chưa có tên",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Email: ${userData['email']}\nQuyền: ${userData['role']}",
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editUser(userId, userData),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteUser(userId),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
