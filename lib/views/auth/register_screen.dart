import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
// import 'login_screen.dart'; // Import để chuyển trang sau khi đăng ký xong

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // 1. Khai báo Form Key để kiểm tra dữ liệu
  final _formKey = GlobalKey<FormState>();

  // 2. Các Controller
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController(); // Thêm SĐT
  final _addressController = TextEditingController(); // Thêm Địa chỉ
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController(); // Thêm xác nhận mật khẩu

  @override
  void dispose() {
    // Giải phóng bộ nhớ khi tắt màn hình
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký tài khoản')),
      // Dùng SingleChildScrollView để cuộn khi bàn phím bật lên
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey, // Gắn key vào Form
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Tạo tài khoản mới",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // --- HỌ TÊN ---
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? "Vui lòng nhập tên" : null,
              ),
              const SizedBox(height: 15),

              // --- EMAIL ---
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => !value!.contains('@') ? "Email không hợp lệ" : null,
              ),
              const SizedBox(height: 15),

              // --- SỐ ĐIỆN THOẠI (Mới) ---
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.length < 9 ? "SĐT không hợp lệ" : null,
              ),
              const SizedBox(height: 15),

              // --- ĐỊA CHỈ (Mới - Quan trọng để mua bán) ---
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ (Tỉnh/Thành phố)',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? "Vui lòng nhập địa chỉ" : null,
              ),
              const SizedBox(height: 15),

              // --- MẬT KHẨU ---
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.length < 6 ? "Mật khẩu phải trên 6 ký tự" : null,
              ),
              const SizedBox(height: 15),

              // --- XÁC NHẬN MẬT KHẨU ---
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nhập lại mật khẩu',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value != _passwordController.text) return "Mật khẩu không khớp";
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // --- NÚT ĐĂNG KÝ ---
              authProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        // 1. Kiểm tra validator
                        if (_formKey.currentState!.validate()) {
                          try {
                            // 2. Gọi hàm đăng ký với đầy đủ thông tin
                            await authProvider.register(
                              _emailController.text.trim(),
                              _passwordController.text.trim(),
                              _nameController.text.trim(),
                              _phoneController.text.trim(),   // Truyền SĐT
                              _addressController.text.trim(), // Truyền Địa chỉ
                            );

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Đăng ký thành công!')),
                              );
                              // Chuyển sang màn hình Home (Vì register xong đã tự login rồi)
                              // Hoặc chuyển về Login tùy logic của bạn
                              Navigator.pop(context); 
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Lỗi: ${e.toString()}")),
                              );
                            }
                          }
                        }
                      },
                      child: const Text('ĐĂNG KÝ NGAY', style: TextStyle(fontSize: 16)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}