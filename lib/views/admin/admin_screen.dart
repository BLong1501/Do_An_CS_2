import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 1. Import Firebase Auth
import 'package:my_app/services/data_seeder.dart';
import '../auth/login_screen.dart'; // 2. Import màn hình Login
import 'tabs/vehicle_approval_tab.dart';
import 'tabs/seller_approval_tab.dart';
import 'tabs/report_tab.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("ADMIN DASHBOARD"),
          backgroundColor: Colors.blueGrey[900],
          foregroundColor: Colors.white,
          
          // --- 3. THÊM NÚT LOGOUT TẠI ĐÂY ---
          actions: [
            IconButton(
              icon: const Icon(Icons.cloud_upload_outlined), // Icon đám mây
              tooltip: "Cập nhật dữ liệu mẫu",
              onPressed: () async {
                // A. Hiện thông báo đang chạy
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Đang đồng bộ dữ liệu hãng xe..."),
                    duration: Duration(seconds: 1),
                  ),
                );

                try {
                  // B. Gọi hàm seedData từ file data_seeder.dart
                  await DataSeeder().seedData();

                  // C. Thông báo thành công
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(" Đã cập nhật dữ liệu thành công!"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  // D. Thông báo lỗi nếu có
                   if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
                    );
                  }
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: "Đăng xuất",
              onPressed: () async {
                // A. Đăng xuất khỏi Firebase
                await FirebaseAuth.instance.signOut();

                // B. Chuyển về màn hình Login & Xóa lịch sử
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false, // Xóa sạch các màn hình trước đó
                  );
                }
              },
            ),
          ],
          // ----------------------------------

          bottom: const TabBar(
            indicatorColor: Colors.orange,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(icon: Icon(Icons.directions_car), text: "Duyệt Xe"),
              Tab(icon: Icon(Icons.verified_user), text: "Nâng cấp"),
              Tab(icon: Icon(Icons.warning), text: "Khiếu nại"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            VehicleApprovalTab(),
            SellerApprovalTab(),
            ReportTab(),
          ],
          
        ),
        
      ),
      
    );
  }
}