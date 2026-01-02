import 'package:flutter/material.dart';
import 'package:my_app/views/admin/admin_vehicle_screen.dart';
import 'package:my_app/views/home/home_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Đăng nhập")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Chào mừng quay trở lại!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 25),
            authProvider.isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: Colors.orange,
                    ),
                    onPressed: () async {
                      // 1. Tắt bàn phím để nhìn cho thoáng
                      FocusScope.of(context).unfocus();

                      try {
                        // 2. Gọi hàm đăng nhập
                        // Lưu ý: Đảm bảo hàm login trong AuthProvider trả về true nếu thành công
                        // Hoặc nếu hàm login trả về void thì dùng try/catch như bạn đang làm là ổn.
                        await authProvider.login(
                          _emailController.text.trim(),
                          _passwordController.text.trim(),
                        );

                        // 3. SAU KHI LOGIN THÀNH CÔNG -> KIỂM TRA ROLE ĐỂ ĐIỀU HƯỚNG
                        if (context.mounted) {
                          final user =
                              authProvider.user; // Lấy thông tin user hiện tại

                          if (user != null) {
                            if (user.role.name == 'admin') {
                              // --- TRƯỜNG HỢP 1: LÀ ADMIN ---
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AdminScreen(),
                                ),
                                (route) =>
                                    false, // Xóa lịch sử để không back lại Login
                              );
                            } else {
                              // --- TRƯỜNG HỢP 2: LÀ USER THƯỜNG ---
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const HomeScreen(),
                                ),
                                (route) => false,
                              );
                            }
                          }
                        }
                      } catch (e) {
                        // 4. Xử lý lỗi nếu đăng nhập thất bại
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Lỗi: ${e.toString()}"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text(
                      "ĐĂNG NHẬP",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
              child: const Text("Chưa có tài khoản? Đăng ký ngay"),
            ),
          ],
        ),
      ),
    );
  }
}
