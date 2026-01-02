// import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:my_app/views/admin/admin_vehicle_screen.dart';
import 'package:my_app/views/home/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Nhớ import cái này
import '../../providers/auth_provider.dart';
import 'register_screen.dart';
import '../../utils/app_dialogs.dart'; // Nhớ import file này

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadUserEmailPassword(); // Tải thông tin đã lưu khi màn hình khởi tạo
  }

  // --- LOGIC 1: TẢI THÔNG TIN ĐÃ LƯU ---
  void _loadUserEmailPassword() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var email = prefs.getString("email") ?? "";
      var password = prefs.getString("password") ?? "";
      var rememberMe = prefs.getBool("remember_me") ?? false;

      if (rememberMe) {
        setState(() {
          _rememberMe = true;
          _emailController.text = email;
          _passwordController.text = password;
        });
      }
    } catch (e) {
      print("Lỗi tải thông tin: $e");
    }
  }

  // --- LOGIC 2: LƯU HOẶC XÓA THÔNG TIN ---
  void _handleRememberMe() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      // Nếu tích chọn -> Lưu lại
      await prefs.setString("email", _emailController.text);
      await prefs.setString("password", _passwordController.text);
      await prefs.setBool("remember_me", true);
    } else {
      // Nếu bỏ chọn -> Xóa đi
      await prefs.remove("email");
      await prefs.remove("password");
      await prefs.setBool("remember_me", false);
    }
  }

  // --- LOGIC 3: QUÊN MẬT KHẨU (Gửi email reset của Firebase) ---
  // void _showForgotPasswordDialog() {
  //   final resetEmailController = TextEditingController();
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text("Quên mật khẩu?"),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           const Text("Nhập email của bạn để nhận link đặt lại mật khẩu."),
  //           const SizedBox(height: 10),
  //           TextField(
  //             controller: resetEmailController,
  //             decoration: const InputDecoration(
  //               labelText: "Email",
  //               border: OutlineInputBorder(),
  //               prefixIcon: Icon(Icons.email),
  //             ),
  //           ),
  //         ],
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text("Hủy"),
  //         ),
  //         ElevatedButton(
  //           style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[300]),
  //           onPressed: () async {
  //             if (resetEmailController.text.isEmpty) return;
  //             try {
  //               // Gọi hàm gửi email của Firebase Auth
  //               await FirebaseAuth.instance.sendPasswordResetEmail(
  //                 email: resetEmailController.text.trim(),
  //               );
  //               if (mounted) {
  //                 Navigator.pop(context);
  //                 ScaffoldMessenger.of(context).showSnackBar(
  //                   const SnackBar(content: Text("Đã gửi link reset pass vào email!")),
  //                 );
  //               }
  //             } catch (e) {
  //               if (mounted) {
  //                 Navigator.pop(context);
  //                 ScaffoldMessenger.of(context).showSnackBar(
  //                   SnackBar(content: Text("Lỗi: ${e.toString()}")),
  //                 );
  //               }
  //             }
  //           },
  //           child: const Text("Gửi", style: TextStyle(color: Colors.white)),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "XE TỐT MARKET",
          style: TextStyle(
            fontSize: 24, // Giảm size chút cho đỡ bị tràn trên máy nhỏ
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue[300],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView( // Thêm cái này để không bị lỗi tràn màn hình khi phím hiện lên
        child: Padding(
          padding: const EdgeInsets.all(30.0), // Giảm padding chút cho thoáng
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                "Đăng Nhập", // Sửa thành tiếng Việt cho đồng bộ
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.blue[800]),
              ),
              const SizedBox(height: 30),
              
              // Field cho email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.blue[300], fontSize: 16),
                  prefixIcon: Icon(Icons.email, color: Colors.blue[300]),
                  border: const UnderlineInputBorder(),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue.shade300, width: 2.0)),
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color.fromARGB(255, 149, 204, 243))),
                ),
              ),
              const SizedBox(height: 15),
              
              // Field mật khẩu
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  labelStyle: TextStyle(color: Colors.blue[300], fontSize: 16),
                  prefixIcon: Icon(Icons.lock, color: Colors.blue[300]),
                  border: const UnderlineInputBorder(),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue.shade300, width: 2.0)),
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color.fromARGB(255, 149, 204, 243))),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Hàng Remember Me & Forgot Password
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        activeColor: Colors.blue[300],
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value!;
                          });
                        },
                      ),
                      const Text("Ghi nhớ"),
                    ],
                  ),
                  TextButton(
                    onPressed: () => AppDialogs.showForgotPasswordDialog(context), // Gọi hàm hiển thị dialog
                    child: Text("Quên mật khẩu?", style: TextStyle(color: Colors.blue[400])),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // Nút Đăng nhập
              authProvider.isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: const Color.fromARGB(255, 39, 88, 194),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        FocusScope.of(context).unfocus(); // Tắt bàn phím

                        try {
                          await authProvider.login(
                            _emailController.text.trim(),
                            _passwordController.text.trim(),
                          );
                          
                          // LƯU THÔNG TIN NẾU CHỌN GHI NHỚ
                          _handleRememberMe(); 

                          if (context.mounted) {
                            final user = authProvider.user;
                            if (user != null) {
                              if (user.role.name == 'admin') {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (_) => const AdminScreen()), // Sửa AdminScreen của bạn ở đây
                                  (route) => false,
                                );
                              } else {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                                  (route) => false,
                                );
                              }
                            }
                          }
                        } catch (e) {
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
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
              
              const SizedBox(height: 20),
              
              // Chuyển sang đăng ký
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Chưa có tài khoản? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: Text(
                      "Đăng ký ngay",
                      style: TextStyle(color: const Color.fromARGB(255, 23, 108, 182), fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}