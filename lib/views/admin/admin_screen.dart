import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import để đếm badge
import 'package:my_app/services/data_seeder.dart';
import 'package:my_app/services/notification_service.dart'; // Import service thông báo
import '../auth/login_screen.dart';
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
          actions: [
            // 1. NÚT GỬI THÔNG BÁO HỆ THỐNG (Mới thêm)
            IconButton(
              icon: const Icon(Icons.notifications_active),
              tooltip: "Gửi thông báo hệ thống",
              onPressed: () {
                _showBroadcastDialog(context);
              },
            ),

            // 2. NÚT SEED DATA (Đã thêm hộp thoại xác nhận an toàn)
            IconButton(
              icon: const Icon(Icons.cloud_upload_outlined),
              tooltip: "Cập nhật dữ liệu mẫu",
              onPressed: () {
                _confirmSeedData(context);
              },
            ),

            // 3. NÚT ĐĂNG XUẤT (Giữ nguyên)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: "Đăng xuất",
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
          
          bottom: TabBar(
            indicatorColor: Colors.orange,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            tabs: [
              // Tab 1: Duyệt xe (Có thể thêm Badge số lượng xe chờ duyệt)
              const Tab(icon: Icon(Icons.directions_car), text: "Duyệt Xe"),
              
              // Tab 2: Nâng cấp Seller
              const Tab(icon: Icon(Icons.verified_user), text: "Nâng cấp"),

              // Tab 3: Khiếu nại
              const Tab(icon: Icon(Icons.warning), text: "Khiếu nại"),
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

  // --- HÀM 1: HỘP THOẠI GỬI THÔNG BÁO HỆ THỐNG ---
  void _showBroadcastDialog(BuildContext context) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Gửi thông báo hệ thống"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Thông báo này sẽ gửi đến TẤT CẢ người dùng.", style: TextStyle(color: Colors.red, fontSize: 12)),
            const SizedBox(height: 10),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Tiêu đề", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: bodyController,
              decoration: const InputDecoration(labelText: "Nội dung", border: OutlineInputBorder()),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty || bodyController.text.isEmpty) return;
              Navigator.pop(ctx);

              // Giả lập gửi cho tất cả user (Thực tế nên dùng Cloud Functions)
              // Ở đây mình demo gửi 1 thông báo dạng "system" vào DB
              // Bạn có thể mở rộng logic để loop qua user list nếu muốn
              
              // Demo: Gửi cho chính Admin để test trước
              final adminId = FirebaseAuth.instance.currentUser!.uid;
              
              await NotificationService().sendNotification(
                receiverId: adminId, 
                title: "[HỆ THỐNG] ${titleController.text}", 
                body: bodyController.text, 
                type: "system"
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã gửi thông báo!")));
              }
            },
            child: const Text("Gửi ngay"),
          ),
        ],
      ),
    );
  }

  // --- HÀM 2: HỘP THOẠI XÁC NHẬN SEED DATA ---
  void _confirmSeedData(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận cập nhật?"),
        content: const Text("Hành động này sẽ thêm dữ liệu mẫu vào Database. Bạn có chắc chắn không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              Navigator.pop(ctx); // Đóng dialog
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Đang đồng bộ dữ liệu...")),
              );

              try {
                await DataSeeder().seedData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Thành công!"), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text("Đồng ý", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}